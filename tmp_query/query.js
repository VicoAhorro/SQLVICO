const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres:osDO0mRq7crrBTMR@db.vlpknvvgixhiznqslzwk.supabase.co:6543/postgres',
});
client.connect();
client.query("SELECT * FROM comparison_light WHERE id = '2fd9d5dd-11ac-4e4d-93b1-58162fa4ab81'", (err, res) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log(JSON.stringify(res.rows[0], null, 2));
  client.end();
});
