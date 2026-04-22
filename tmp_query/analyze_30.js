const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres:osDO0mRq7crrBTMR@db.vlpknvvgixhiznqslzwk.supabase.co:6543/postgres',
});
client.connect();
async function run() {
  try {
    console.log('--- Comparison Input Data ---');
    const resComp = await client.query("SELECT * FROM comparison_3_0 WHERE id = 'a1093a40-c73e-45b7-aa4d-61677f501189'");
    if (resComp.rows.length === 0) {
      console.log('No comparison found with this ID.');
      return;
    }
    const comp = resComp.rows[0];
    console.log(JSON.stringify(comp, null, 2));

    console.log('\n--- View Results ---');
    const resView = await client.query("SELECT * FROM _comparisons_detailed_3_0 WHERE id = 'a1093a40-c73e-45b7-aa4d-61677f501189'");
    console.log('Number of rows in view:', resView.rows.length);

    if (resView.rows.length === 0) {
      console.log('\n--- Troubleshooting Filters ---');
      // Let's check candidate rates that match type = '3_0'
      const resRatesCount = await client.query("SELECT count(*) FROM comparison_rates WHERE type = '3_0' AND deleted = false");
      console.log('Total candidate 3.0 rates in DB:', resRatesCount.rows[0].count);

      // Check for 'Fija -> Indexada' condition since we recently modified it
      console.log('rate_i_have:', comp.rate_i_have, 'rate_i_want:', comp.rate_i_want);
      
      // Let's see why the join might be failing by looking at some key filters manually
      const resCandidates = await client.query(`
        SELECT cr.id, cr.company, cr.rate_mode, cr.cif, cr.region, cr.subrate_name
        FROM comparison_rates cr
        WHERE cr.type = '3_0' AND cr.deleted = false
        LIMIT 5
      `);
      console.log('\nSample rates in DB:');
      console.log(JSON.stringify(resCandidates.rows, null, 2));
    }
  } catch (err) {
    console.error(err);
  } finally {
    client.end();
  }
}
run();
