const authService = require("../services/auth.service");
const { registerSchema, loginSchema, updateProfileSchema } = require("../validators/auth.validator");

const sendError = (res, error) => {
  const statusCode = error.statusCode || 500;

  return res.status(statusCode).json({
    success: false,
    message: statusCode === 500 ? "Internal server error" : error.message,
  });
};

const formatValidationMessage = (error) => {
  return error.issues.map((issue) => issue.message).join(", ");
};

const register = async (req, res) => {
  const validation = registerSchema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({
      success: false,
      message: formatValidationMessage(validation.error),
    });
  }

  try {
    const user = await authService.register(validation.data);

    return res.status(201).json({
      success: true,
      data: user,
    });
  } catch (error) {
    return sendError(res, error);
  }
};

const login = async (req, res) => {
  const validation = loginSchema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({
      success: false,
      message: formatValidationMessage(validation.error),
    });
  }

  try {
    const data = await authService.login(validation.data);

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    return sendError(res, error);
  }
};

const getProfile = async (req, res) => {
  try {
    const user = await authService.getProfile(req.user.id);

    return res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    return sendError(res, error);
  }
};

const updateProfile = async (req, res) => {
  const validation = updateProfileSchema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({
      success: false,
      message: formatValidationMessage(validation.error),
    });
  }

  try {
    const user = await authService.updateProfile(req.user.id, validation.data);

    return res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    return sendError(res, error);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
};
