require! {
  request
  cheerio
  fs
  mysql
  iconv: 'iconv-lite'
}
conn = mysql.createConnection({
  host: 'localhost'
  user: 'npodata'
  database: 'npodata'
  password: '7tNnc4pXAUWu6tEF'
})
url = 'http://donate.mohw.gov.tw/web/'
error,response,body <- request({
  'url':url+'apply_all_page.asp'
  'encoding':null
  'method': 'POST'
  'qs': {a_date:'1'}
})
if (!error && response.statusCode == 200)
  b = iconv.decode(new Buffer(body), "big5")
  $ = cheerio.load(b)
  rows = $ 'table.text_middle tr'
  j = 0
  rows_loop = ->
    setTimeout (->
      r = rows[j]
      j++
      a = $ r .find('td').eq(0)
      b = $ r .find('td').eq(1)
      c = $ r .find('td').eq(2)
      d = $ r .find('td').eq(3)
      href = a.find('a').attr('href')
      matches = /num=(\d+)/.exec(href)
      if(matches?)
        id = matches[1]
        err,selected <- conn.query('SELECT id FROM `data` WHERE unix_timestamp(now()) - unix_timestamp(`timestamp`) < 86400*30 AND id = ?', id)
        if(selected.length < 1)
          # start to fetch 
          org = b.text()
          title = c.text()
          date = d.text().split('～')
          if(date.length)
            start = yearc(date[0])
            end = yearc(date[1])
            json =
              id: id
              org: org
              title: title
              start: start
              end: end
            grab_detail(json)
        else
          console.log 'skipped '+ id
      rows_loop! if j < rows.length), 100
  rows_loop()

# helper functions
function grab_detail(o)
  url = 'http://donate.mohw.gov.tw/web/'
  error,response,body <- request({
    'url':url+'apply_all.asp'
    'encoding':null
    'method': 'GET'
    'qs': {num:o.id}
  })
  b = iconv.decode(new Buffer(body), "big5")
  $ = cheerio.load(b)
  # decode the cell to pair
  inner_table = $ 'table.text_middle table.text_middle'
  inner_table = '<table>'+inner_table.html()+'</table>'
  $ 'table.text_middle table.text_middle' .remove()
  rows = $ 'table.text_middle tr'

  for tr in rows
    a = $ tr .find('td').eq(0)
    b = $ tr .find('td').eq(1)
    c = $ tr .find('td').eq(2)
    d = $ tr .find('td').eq(3)
    htm = key = null
    if(a && b)
      key = a.text() - /(\r\n|\n|\r|^\s+|\s+$)/gm
      if(key)
        if(key == '結束備查文件')
          htm = inner_table
        else
          htm = b.html() - /(\r\n|\n|\r|^\s+|\s+$)/gm
        htm = validate(key, htm)
        if(htm)
          o[key] = htm
    if(c && d)
      key = c.text() - /(\r\n|\n|\r|^\s+|\s+$)/gm
      if(key)
        htm = d.html() - /(\r\n|\n|\r|^\s+|\s+$)/gm
        htm = validate(key, htm)
        if(htm)
          o[key] = htm
  # console.log o
  do
    err,rows <- conn.query('REPLACE INTO data SET?', o)
    console.log('inserted ' + o.id)

function validate(key, htm)
  switch key
  | '申請單位' => return null
  | '活動名稱' => return null
  | '勸募活動開始' => return null
  | '勸募活動結束' => return null
  | '所得財物使用年限' => return yearrange(htm)
  | '賸餘財物再使用年限' => return yearrange(htm)
  | otherwise =>
    if(htm.indexOf('a href'))
      return convertlink(htm)
    else
      if(/^\d+$/.test(htm))
        return parseInt(htm)
      else
        return clearentity(htm)

# decode taiwan year
function yearc(d)
  d = d.replace(/年度|月/g, '/') - /日/
  date = d.split('/')
  date[0] = parseInt(date[0])+1911
  return date.join('/')

function yearrange(d)
  d = d.replace(/^到|到$/, '')
  if(d.match('到'))
    d = d.split('到')
    if(d[0]?)
      d[0] = yearc(d[0])
    if(d[1]?)
      d[1] = yearc(d[1])
    return d * '~'
  else
    return yearc(d)

function clearhtm(h)
  h = h - /<\/?[^>+]>/gm
  return clearentity(h)

function clearentity(h)
  return h - /&.{0,}?;/gm

function convertlink(h)
  $ = cheerio.load(h)
  links = $ 'a'
  for a in links
    href = $ a .attr('href').replace(/^\.\.\//, 'http://donate.mohw.gov.tw/')
    $ a .attr('href', href)
  return $.html()

# debug usage
function grabl(s)
  if s?
    b = fs.readFileSync('debug2.htm', 'utf-8')
  else
    b = fs.readFileSync('debug.htm', 'utf-8')
  return cheerio.load(b)

