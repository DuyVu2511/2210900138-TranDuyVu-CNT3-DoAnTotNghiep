const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true }, // SĐT là duy nhất
  password: { type: String, required: true },
  name: { type: String, required: true },
  role: { type: String, default: 'user' }, // user: Người dân, admin: Cán bộ
});

module.exports = mongoose.model('User', userSchema);