const express = require('express');
const router = express.Router();
const User = require('../models/User');

// 1. API ĐĂNG KÝ
// POST: http://localhost:3000/api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { phone, password, name } = req.body;

    // Kiểm tra xem SĐT đã tồn tại chưa
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ message: "Số điện thoại này đã được đăng ký!" });
    }

    // Tạo người dùng mới
    const newUser = new User({ phone, password, name });
    await newUser.save();

    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 2. API ĐĂNG NHẬP
// POST: http://localhost:3000/api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Tìm user theo SĐT
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ message: "Tài khoản không tồn tại!" });
    }

    // Kiểm tra mật khẩu (Lưu ý: Làm đồ án thì so sánh trực tiếp cho dễ, làm thật phải mã hóa)
    if (user.password !== password) {
      return res.status(400).json({ message: "Sai mật khẩu!" });
    }

    // Trả về thông tin user nếu đúng
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;