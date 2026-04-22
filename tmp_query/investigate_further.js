const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres:osDO0mRq7crrBTMR@db.vlpknvvgixhiznqslzwk.supabase.co:6543/postgres',
});
client.connect();
async function run() {
  try {
    const resComp = await client.query("SELECT * FROM comparison_3_0 WHERE id = 'a1093a40-c73e-45b7-aa4d-61677f501189'");
    const comp = resComp.rows[0];
    console.log('--- Comparison Current State ---');
    console.log(JSON.stringify(comp, null, 2));

    console.log('\n--- Checking Candidates manually ---');
    const query = `
      SELECT id, company, rate_name, subrate_name, rate_mode, cif, region, has_permanence, has_gdo
      FROM comparison_rates
      WHERE type = '3_0'
        AND deleted = false
        AND company <> '${comp.company}'
        AND rate_mode = 'Fija'
        AND (cif IS NULL OR cif = ${comp.cif})
        AND '${comp.region}' = ANY(region)
        AND (subrate_name = '${comp.preferred_subrate}' OR '${comp.preferred_subrate}' = '' OR '${comp.preferred_subrate}' IS NULL)
    `;
    const resRates = await client.query(query);
    console.log('Candidates matching CIF, Region, Company, Subrate, Mode:', resRates.rows.length);
    
    if (resRates.rows.length > 0) {
        console.log('\nAnalyzing candidates for permanence and GDO:');
        resRates.rows.forEach(r => {
            const permMatch = (comp.wants_permanence === false && (r.has_permanence === false || r.has_permanence === null)) || comp.wants_permanence === null;
            const gdoMatch = (comp.wants_gdo === false || r.has_gdo === true);
            console.log(`Rate: ${r.rate_name} (${r.company}) | HasPerm: ${r.has_permanence} | WantsPerm: ${comp.wants_permanence} | MatchPerm: ${permMatch} | MatchGDO: ${gdoMatch}`);
        });
    }

  } catch (err) {
    console.error(err);
  } finally {
    client.end();
  }
}
run();
