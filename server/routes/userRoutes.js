const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Report = require('../models/Report'); // Import thêm Model này

// API Cập nhật thông tin User & Đồng bộ tên
// PUT: /api/users/:id
router.put('/:id', async (req, res) => {
  try {
    console.log("--- BẮT ĐẦU UPDATE USER (API USERS) ---");

    // 1. Update User
    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { name: req.body.name },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ message: "Không tìm thấy User" });
    }

    // 2. Đồng bộ tên sang Report
    if (req.body.name) {
        const result = await Report.updateMany(
            { userId: req.params.id },
            { $set: { userName: req.body.name } }
        );
        console.log("Đã đồng bộ tên cho Report:", result);
    }

    res.json(updatedUser);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;