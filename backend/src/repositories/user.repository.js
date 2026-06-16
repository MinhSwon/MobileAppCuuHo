const prisma = require("../config/database");

const findById = (id) => {
  return prisma.user.findUnique({
    where: { id },
  });
};

const findByEmail = (email) => {
  return prisma.user.findUnique({
    where: { email },
  });
};

const create = (data) => {
  return prisma.user.create({
    data,
  });
};

const update = (id, data) => {
  return prisma.user.update({
    where: { id },
    data,
  });
};

module.exports = {
  findById,
  findByEmail,
  create,
  update,
};
