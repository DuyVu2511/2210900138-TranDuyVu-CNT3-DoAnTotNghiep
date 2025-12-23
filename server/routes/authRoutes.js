const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken'); // 1. IMPORT THƯ VIỆN JWT (Mới thêm)

// KHÓA BÍ MẬT (Dùng để ký tên vào Token, đừng để lộ ra ngoài)
const JWT_SECRET = 'khoa_bi_mat_doan_tot_nghiep_2025';

// 1. API ĐĂNG KÝ
router.post('/register', async (req, res) => {
  try {
    const { phone, password, name } = req.body;

    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ message: "Số điện thoại này đã được đăng ký!" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
        phone,
        password: hashedPassword,
        name,
        role: 'user' // Mặc định là user thường
    });

    await newUser.save();

    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 2. API ĐĂNG NHẬP (QUAN TRỌNG: ĐÃ SỬA ĐỂ TRẢ VỀ TOKEN)
router.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Tìm user
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ message: "Tài khoản không tồn tại!" });
    }

    // So sánh mật khẩu
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Sai mật khẩu!" });
    }

    // --- BẮT ĐẦU PHẦN JWT (MỚI THÊM) ---

    // Tạo Payload (Dữ liệu muốn giấu trong token)
    const payload = {
        id: user._id,
        role: user.role || 'user'
    };

    // Ký tên tạo Token (Hết hạn sau 30 ngày)
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '30d' });

    // --- KẾT THÚC PHẦN JWT ---

    // Xóa password trước khi trả về
    const userResponse = user.toObject();
    delete userResponse.password;

    // TRẢ VỀ CẢ USER VÀ TOKEN
    res.json({
        token: token,      // <--- ĐÂY LÀ CÁI FLUTTER CẦN
        user: userResponse
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;