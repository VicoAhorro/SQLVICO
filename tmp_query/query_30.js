const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres:osDO0mRq7crrBTMR@db.vlpknvvgixhiznqslzwk.supabase.co:6543/postgres',
});
client.connect();
async function run() {
  try {
    const resComp = await client.query("SELECT * FROM comparison_3_0 WHERE id = '59663f26-82ca-4f25-b3f0-98f8c7c512e8'");
    console.log('Comparison Data:');
    console.log(JSON.stringify(resComp.rows[0], null, 2));

    const resView = await client.query("SELECT * FROM _comparisons_detailed_3_0 WHERE id = '59663f26-82ca-4f25-b3f0-98f8c7c512e8'");
    console.log('\nView Results (Ranked):');
    console.log(JSON.stringify(resView.rows, null, 2));

    if (resView.rows.length > 0) {
        const rateId = resView.rows[0].new_rate_id;
        const resRate = await client.query("SELECT * FROM comparison_rates WHERE id = ", [rateId]);
        console.log('\nReturned Rate Data:');
        console.log(JSON.stringify(resRate.rows[0], null, 2));
    }
  } catch (err) {
    console.error(err);
  } finally {
    client.end();
  }
}
run();
