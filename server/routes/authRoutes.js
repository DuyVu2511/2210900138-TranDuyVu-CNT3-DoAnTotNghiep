const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcryptjs'); // 1. Import thư viện mã hóa

// 1. API ĐĂNG KÝ (CÓ MÃ HÓA)
router.post('/register', async (req, res) => {
  try {
    const { phone, password, name } = req.body;

    // Kiểm tra trùng lặp
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ message: "Số điện thoại này đã được đăng ký!" });
    }

    // 2. MÃ HÓA MẬT KHẨU TRƯỚC KHI LƯU
    const salt = await bcrypt.genSalt(10); // Tạo chuỗi ngẫu nhiên (muối)
    const hashedPassword = await bcrypt.hash(password, salt); // Trộn mật khẩu với muối

    // Lưu vào DB (lưu mật khẩu đã mã hóa, không lưu mật khẩu thật)
    const newUser = new User({
        phone,
        password: hashedPassword, // <--- Lưu cái này
        name
    });

    await newUser.save();

    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 2. API ĐĂNG NHẬP (SO SÁNH MÃ HÓA)
router.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Tìm user
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ message: "Tài khoản không tồn tại!" });
    }

    // 3. SO SÁNH MẬT KHẨU NHẬP VÀO VỚI MẬT KHẨU MÃ HÓA TRONG DB
    // (Không được so sánh === trực tiếp nữa)
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({ message: "Sai mật khẩu!" });
    }

    // Trả về user (nhưng đừng trả về password)
    const userResponse = user.toObject();
    delete userResponse.password; // Xóa field password khỏi kết quả trả về cho an toàn

    res.json(userResponse);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;