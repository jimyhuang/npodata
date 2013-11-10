require! {
  mysql
}

conn = mysql.createConnection({
  host: 'localhost'
  user: 'npodata'
  database: 'npodata'
  password: '7tNnc4pXAUWu6tEF'
})

# yearly count
do
  err,rows <- conn.query('SELECT YEAR(`end`), count(id), sum(`預募金額`) as expect, sum(`實募金額`) as actual FROM `data` group by YEAR(`end`) ORDER BY YEAR(`end`)')
  console.log  rows

do
  err,rows <- conn.query('SELECT org, count(id), group_concat(YEAR(`end`)), sum(`預募金額`) as expect, sum(`實募金額`) as actual FROM `data` group by `org` ORDER BY sum(`實募金額`) DESC, count(id) DESC')
  console.log  rows
