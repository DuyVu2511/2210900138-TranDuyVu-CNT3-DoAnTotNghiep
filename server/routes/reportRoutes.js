const express = require('express');
const router = express.Router();
const Report = require('../models/Report');
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: 'dqz4kwlgq',
  api_key: '864719659715351',
  api_secret: 'jol9YIlFLg4ocAhXjSlTe5_mwMY'
});

// 1. API: Lấy tất cả báo cáo (Sắp xếp mới nhất lên đầu)
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

// 3. API: Xóa báo cáo.
router.delete('/:id', async (req, res) => {
  try {
    // A. Tìm báo cáo trước
    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({ message: "Không tìm thấy báo cáo" });
    }

    // B. Nếu có ảnh -> Xóa trên Cloudinary
    if (report.imagePath && report.imagePath.includes('cloudinary')) {
      try {
        console.log("Đang xóa ảnh:", report.imagePath);

        // --- CÔNG THỨC TÁCH ID CHUẨN XÁC ---
        // Lấy tất cả ký tự nằm sau chữ 'upload/' (và bỏ qua đoạn v12345/ nếu có) cho đến dấu chấm .jpg
        // Ví dụ: .../upload/v171234/disaster_upload/abc.jpg -> Lấy "disaster_upload/abc"
        const regex = /\/upload\/(?:v\d+\/)?(.+)\.[^.]+$/;
        const match = report.imagePath.match(regex);

        if (match && match[1]) {
            const publicId = match[1];
            console.log("Public ID tìm được:", publicId);

            // Gọi lệnh xóa
            const result = await cloudinary.uploader.destroy(publicId);
            console.log("Kết quả Cloudinary:", result); // Nếu hiện { result: 'ok' } là ngon
        } else {
            console.log("❌ Không tách được ID từ link này.");
        }
      } catch (err) {
        console.log("❌ Lỗi xóa ảnh Cloud:", err);
      }
    }

    // C. Xóa trong MongoDB
    await Report.findByIdAndDelete(req.params.id);

    res.json({ message: "Đã xóa báo cáo và ảnh thành công!" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 4. API: Cập nhật báo cáo
// PUT: http://localhost:3000/api/reports/:id
router.put('/:id', async (req, res) => {
  try {
    const updatedReport = await Report.findByIdAndUpdate(
      req.params.id,
      req.body, // Dữ liệu mới gửi lên
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