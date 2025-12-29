const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Report = require('../models/Report');

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

// 3. API ĐỔI MẬT KHẨU (MỚI THÊM)
// POST: http://localhost:3000/api/auth/change-password
router.post('/change-password', async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        if (oldPassword === newPassword) {
                    return res.status(400).json({ message: "Mật khẩu mới không được trùng với mật khẩu cũ!" });
        }

        // 1. Lấy Token từ Header (Authorization: Bearer <token>)
        const token = req.header('Authorization').replace('Bearer ', '');
        if (!token) {
            return res.status(401).json({ message: "Không có quyền truy cập (Thiếu Token)" });
        }

        // 2. Giải mã Token để lấy ID User
        const decoded = jwt.verify(token, JWT_SECRET);
        const userId = decoded.id; // Lấy ID từ payload lúc login

        // 3. Tìm User trong DB
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: "User không tồn tại" });
        }

        // 4. QUAN TRỌNG: Kiểm tra mật khẩu CŨ có đúng không
        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: "Mật khẩu cũ không đúng!" });
        }

        // 5. Nếu đúng, Mã hóa mật khẩu MỚI
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(newPassword, salt);

        // 6. Lưu vào DB
        await user.save();

        res.json({ message: "Đổi mật khẩu thành công!" });

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Lỗi Server hoặc Token hết hạn" });
    }
});

module.exports = router;