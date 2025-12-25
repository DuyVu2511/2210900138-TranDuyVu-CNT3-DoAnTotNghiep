const express = require('express');
const router = express.Router();
const Report = require('../models/Report'); // Đảm bảo đường dẫn đúng
const cloudinary = require('cloudinary').v2;

// Cấu hình Cloudinary (Giữ nguyên key của bạn)
cloudinary.config({
  cloud_name: 'dqz4kwlgq',
  api_key: '864719659715351',
  api_secret: 'jol9YIlFLg4ocAhXjSlTe5_mwMY'
});

// 1. API: Lấy tất cả báo cáo (Mới nhất lên đầu)
// GET: http://localhost:3000/api/reports
router.get('/', async (req, res) => {
  try {
    const reports = await Report.find().sort({ timestamp: -1 });
    res.json(reports);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 2. API: Gửi báo cáo mới
// POST: http://localhost:3000/api/reports
router.post('/', async (req, res) => {
  const newReport = new Report(req.body);
  try {
    const savedReport = await newReport.save();
    console.log("Đã lưu báo cáo mới:", savedReport.title);
    res.status(201).json(savedReport);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// 3. API: Xóa báo cáo (Kèm xóa ảnh trên Cloudinary)
// DELETE: http://localhost:3000/api/reports/:id
router.delete('/:id', async (req, res) => {
  try {
    // A. Tìm báo cáo trước để lấy link ảnh
    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({ message: "Không tìm thấy báo cáo" });
    }

    // B. Nếu có ảnh -> Xóa trên Cloudinary để tiết kiệm bộ nhớ
    if (report.imagePath && report.imagePath.includes('cloudinary')) {
      try {
        console.log("Đang xóa ảnh:", report.imagePath);

        // Regex tách Public ID từ link ảnh
        const regex = /\/upload\/(?:v\d+\/)?(.+)\.[^.]+$/;
        const match = report.imagePath.match(regex);

        if (match && match[1]) {
            const publicId = match[1];
            await cloudinary.uploader.destroy(publicId);
            console.log("Đã xóa ảnh trên Cloudinary:", publicId);
        }
      } catch (err) {
        console.log("Lỗi xóa ảnh (không ảnh hưởng việc xóa bài):", err);
      }
    }

    // C. Xóa báo cáo trong Database
    await Report.findByIdAndDelete(req.params.id);

    res.json({ message: "Đã xóa báo cáo và ảnh thành công!" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 4. API: Cập nhật báo cáo (Dùng cho Admin sửa nội dung hoặc App sửa bài)
// PUT: http://localhost:3000/api/reports/:id
router.put('/:id', async (req, res) => {
  try {
    const updatedReport = await Report.findByIdAndUpdate(
      req.params.id,
      req.body, // Dữ liệu mới gửi lên (VD: { title: 'Sửa lại', status: 'resolved' })
      { new: true } // Trả về dữ liệu mới sau khi sửa
    );

    if (!updatedReport) {
      return res.status(404).json({ message: "Không tìm thấy báo cáo để sửa" });
    }

    console.log("Đã cập nhật báo cáo:", updatedReport.title);
    res.json(updatedReport);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

module.exports = router;