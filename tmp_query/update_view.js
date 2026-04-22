const { Client } = require('pg');
const fs = require('fs');
const client = new Client({
  connectionString: 'postgresql://postgres:osDO0mRq7crrBTMR@db.vlpknvvgixhiznqslzwk.supabase.co:6543/postgres',
});
const sql = fs.readFileSync('../_comparisons_detailed_3_0.sql', 'utf8');
client.connect();
client.query(sql, (err, res) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log('View updated successfully');
  client.query("SELECT new_rate_id FROM _comparisons_detailed_3_0 WHERE id = '59663f26-82ca-4f25-b3f0-98f8c7c512e8'", (err2, res2) => {
    if (err2) console.error(err2);
    else console.log('New Result for test ID:', res2.rows[0]);
    client.end();
  });
});
