const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/authRoutes');

const app = express();
const PORT = 3000;

// Cấu hình Middleware
app.use(cors()); // Cho phép App Flutter gọi vào
app.use(bodyParser.json()); // Cho phép đọc dữ liệu JSON

// Kết nối MongoDB
// LƯU Ý: Đây là chuỗi kết nối Local (chạy trên máy tính của bạn).
// Nếu bạn chưa cài MongoDB Compass/Community, bước này sẽ báo lỗi.
const mongoURI = "mongodb+srv://duyvutran2004_db_user:01232317428Aa@cluster0.7m2rgse.mongodb.net/?appName=Cluster0";

mongoose.connect(mongoURI)
  .then(() => console.log('✅ Đã kết nối MongoDB thành công!'))
  .catch(err => console.log('❌ Lỗi kết nối MongoDB:', err));

// Import Routes
const reportRoutes = require('./routes/reportRoutes');
app.use('/api/reports', reportRoutes);

app.use('/api/auth', authRoutes);

// Route kiểm tra server
app.get('/', (req, res) => {
  res.send('Server Cảnh báo thiên tai đang chạy 🚀');
});

// Khởi động Server
app.listen(PORT, () => {
  console.log(`Server đang chạy tại http://localhost:${PORT}`);
});