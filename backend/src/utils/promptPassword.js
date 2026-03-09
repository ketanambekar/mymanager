const readline = require('readline');

async function promptMySqlPassword() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question('Please enter your MySQL password: ', (password) => {
      rl.close();
      resolve(password || '');
    });
  });
}

module.exports = { promptMySqlPassword };
