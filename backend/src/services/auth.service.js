const userRepository = require("../repositories/user.repository");
const { hashPassword, comparePassword } = require("../utils/hash");
const { generateAccessToken } = require("../utils/jwt");

const createError = (statusCode, message) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

const sanitizeUser = (user) => {
  const { passwordHash, ...safeUser } = user;
  return safeUser;
};

const register = async (data) => {
  const existingUser = await userRepository.findByEmail(data.email);

  if (existingUser) {
    throw createError(409, "Email is already registered");
  }

  const passwordHash = await hashPassword(data.password);

  try {
    const user = await userRepository.create({
      fullName: data.fullName,
      phone: data.phone,
      email: data.email,
      passwordHash,
    });

    return sanitizeUser(user);
  } catch (error) {
    if (error.code === "P2002") {
      const field = Array.isArray(error.meta?.target) ? error.meta.target[0] : "field";
      throw createError(409, `${field} is already registered`);
    }

    throw error;
  }
};

const login = async (data) => {
  const user = await userRepository.findByEmail(data.email);

  if (!user) {
    throw createError(401, "Invalid email or password");
  }

  if (user.status !== "ACTIVE") {
    throw createError(403, "User account is not active");
  }

  const isPasswordValid = await comparePassword(data.password, user.passwordHash);

  if (!isPasswordValid) {
    throw createError(401, "Invalid email or password");
  }

  const token = generateAccessToken(user);

  return {
    token,
    user: sanitizeUser(user),
  };
};

const getProfile = async (userId) => {
  const user = await userRepository.findById(userId);

  if (!user) {
    throw createError(404, "User not found");
  }

  return sanitizeUser(user);
};

const updateProfile = async (userId, data) => {
  const user = await userRepository.findById(userId);

  if (!user) {
    throw createError(404, "User not found");
  }

  const updateData = {};

  if (data.fullName !== undefined) {
    updateData.fullName = data.fullName;
  }

  if (data.phone !== undefined) {
    updateData.phone = data.phone;
  }

  try {
    const updatedUser = await userRepository.update(userId, updateData);
    return sanitizeUser(updatedUser);
  } catch (error) {
    if (error.code === "P2025") {
      throw createError(404, "User not found");
    }

    if (error.code === "P2002") {
      const field = Array.isArray(error.meta?.target) ? error.meta.target[0] : "field";
      throw createError(409, `${field} is already registered`);
    }

    throw error;
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
};
