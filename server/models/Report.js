const mongoose = require('mongoose');

// Định nghĩa khuôn mẫu cho một bản báo cáo
const reportSchema = new mongoose.Schema({
  title: String,
  description: String,
  type: String, // Loại thiên tai: flood, storm, fire...
  location: {
    latitude: Number,
    longitude: Number
  },
  radius: Number, // Bán kính ảnh hưởng
  imagePath: String, // Đường dẫn ảnh (tạm thời lưu string)
  timestamp: { type: Date, default: Date.now }, // Thời gian tạo (tự động)
  userId: { type: String, required: true },
  userName: String
});

module.exports = mongoose.model('Report', reportSchema);