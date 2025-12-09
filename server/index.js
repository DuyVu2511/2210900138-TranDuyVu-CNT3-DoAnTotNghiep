const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/authRoutes');
const reportRoutes = require('./routes/reportRoutes'); // Import ở trên cùng cho gọn

const app = express();

// --- SỬA ĐỔI QUAN TRỌNG 1: CỔNG (PORT) ---
// Render sẽ cung cấp cổng qua process.env.PORT.
// Nếu chạy ở máy nhà (không có process.env.PORT), nó sẽ lấy số 3000.
const PORT = process.env.PORT || 3000;

// Cấu hình Middleware
app.use(cors());
app.use(bodyParser.json());

// --- SỬA ĐỔI QUAN TRỌNG 2: MONGODB URI ---
// Ưu tiên lấy chuỗi kết nối từ Biến môi trường (bạn đã nhập trên web Render).
// Nếu không có (lúc chạy ở nhà), nó sẽ dùng chuỗi cứng phía sau.
const mongoURI = process.env.MONGO_URI || "mongodb+srv://duyvutran2004_db_user:01232317428Aa@cluster0.7m2rgse.mongodb.net/?appName=Cluster0";

mongoose.connect(mongoURI)
  .then(() => console.log('✅ Đã kết nối MongoDB thành công!'))
  .catch(err => console.log('❌ Lỗi kết nối MongoDB:', err));

// Sử dụng Routes
app.use('/api/reports', reportRoutes);
app.use('/api/auth', authRoutes);

// Route kiểm tra server
app.get('/', (req, res) => {
  res.send('Server Cảnh báo thiên tai đang chạy 🚀');
});

// Khởi động Server
// Lắng nghe ở cổng 0.0.0.0 để Render có thể truy cập
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server đang chạy tại cổng ${PORT}`);
});