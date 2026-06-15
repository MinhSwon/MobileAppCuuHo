const { z } = require("zod");

const vietnamesePhoneRegex = /^(?:\+84|84|0)(?:3|5|7|8|9)\d{8}$/;

const registerSchema = z.object({
  fullName: z.string().trim().min(1, "Full name is required"),
  phone: z.string().trim().min(1, "Phone is required"),
  email: z.string().trim().email("Email is invalid").transform((email) => email.toLowerCase()),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

const loginSchema = z.object({
  email: z.string().trim().email("Email is invalid").transform((email) => email.toLowerCase()),
  password: z.string().min(1, "Password is required"),
});

const updateProfileSchema = z
  .object({
    fullName: z.string().trim().min(3, "Full name must be at least 3 characters").optional(),
    phone: z.string().trim().regex(vietnamesePhoneRegex, "Phone must be a valid Vietnamese phone number").optional(),
  })
  .strict()
  .refine((data) => data.fullName !== undefined || data.phone !== undefined, {
    message: "At least one profile field is required",
  });

module.exports = {
  registerSchema,
  loginSchema,
  updateProfileSchema,
};
