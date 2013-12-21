require! {
  mysql
  moment
  jade
  http
}

conn = mysql.createConnection {
  host: 'localhost'
  user: 'npodata'
  database: 'aaa'
  password: 'bbb'
}
port = 8888

do
  req,res <- http.createServer
  err,rows <- conn.query 'SELECT YEAR(`end`), count(id), sum(`預募金額`) as expect, sum(`實募金額`) as actual FROM `data` group by YEAR(`end`) ORDER BY YEAR(`end`)'

  err,rows <- conn.query 'SELECT org, count(id), group_concat(YEAR(`end`)), sum(`預募金額`) as expect, sum(`實募金額`) as actual FROM `data` group by `org` ORDER BY sum(`實募金額`) DESC, count(id) DESC'

  html = jade.renderFile \./templates/index.jade \utf-8
  res.writeHead 200, {'Content-Type': 'text/html'}
  res.end html
.listen port
