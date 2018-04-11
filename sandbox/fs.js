// ファイル読み込み、書き込み、比較テスト用

const fs = require('fs')

FILE_PATH = './github_reviewers.log'

// ファイルがなければ終了する
if (!isExistFile(FILE_PATH))
  writeFile(FILE_PATH, 'test')


console.info('isExistFile')

read_data = fs.readFileSync(FILE_PATH, 'utf8')

console.info('read')

console.log(read_data)

action_data = 'test2'

// 差分があれば、書き込み
if (read_data != action_data) {
  console.log('差分あり')
  writeFile(FILE_PATH, action_data)
}

console.info('done')



// ファイルの存在確認
function isExistFile(path) {
  try {
    fs.statSync(path)
    return true
  } catch(err) {
    if(err.code === 'ENOENT') return false
  }
}


//ファイル書き込み関数
function writeFile(path, data) {
  fs.writeFile(path, data, function (err) {
    if (err) {
      console.log(err)
      throw err
    }

    console.log('The file has been saved!')
  })
}