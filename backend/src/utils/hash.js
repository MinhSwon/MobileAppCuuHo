const bcrypt = require("bcrypt");

const SALT_ROUNDS = 10;

const hashPassword = (password) => {
  return bcrypt.hash(password, SALT_ROUNDS);
};

const comparePassword = (password, hash) => {
  return bcrypt.compare(password, hash);
};

module.exports = {
  hashPassword,
  comparePassword,
};
