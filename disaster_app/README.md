# HỆ THỐNG CẢNH BÁO VÀ ỨNG PHÓ THIÊN TAI
**(Disaster Warning and Response System)**

> **Đồ án Tốt nghiệp - Ngành Công nghệ Thông tin**
> **Trường Đại học Nguyễn Trãi**

---

# I. ĐỀ TÀI
**Tên đề tài:** Hệ thống cảnh báo và Ứng phó thiên tai.

# II. NỘI DUNG ĐỀ TÀI

### 1. Nội dung, phạm vi của đề tài
**a. Nội dung nghiên cứu:**
- Nghiên cứu các quy trình báo cáo và xử lý thông tin khẩn cấp từ cộng đồng.
- Xây dựng bản đồ số (Digital Map) hiển thị các điểm thiên tai theo thời gian thực.
- Phát triển hệ thống định vị GPS và cơ chế phát tín hiệu cầu cứu (SOS).

**b. Phạm vi thực hiện:**
- **Mobile App (Người dùng):** Cho phép người dân xem bản đồ, gửi báo cáo (kèm ảnh, vị trí), nhận cảnh báo và kích hoạt SOS.
- **Backend Server:** Xử lý logic, xác thực người dùng, lưu trữ dữ liệu không gian (Geospatial) và hình ảnh.

### 2. Công nghệ, công cụ và ngôn ngữ lập trình
- **Ngôn ngữ lập trình:** Dart (Mobile), JavaScript (Backend).
- **Mobile Framework:** Flutter (Android/iOS).
- **Backend Framework:** Node.js, Express.js.
- **Database:** MongoDB (Lưu trữ NoSQL, tối ưu cho GeoJSON).
- **Bản đồ:** OpenStreetMap, thư viện `flutter_map`.
- **Lưu trữ ảnh:** Cloudinary.
- **Công cụ:** Visual Studio Code, Android Studio, Postman, Git.

### 3. Các kết quả chính dự kiến đạt được
- Ứng dụng hoạt động ổn định trên thiết bị di động (Android).
- Chức năng bản đồ tương tác: Zoom, Pan, hiển thị Marker đa dạng (Lụt, Cháy, Bão...).
- Chức năng SOS khẩn cấp với hiệu ứng ưu tiên hiển thị.
- Hệ thống báo cáo thông minh: Gom nhóm marker khi trùng vị trí, upload ảnh thực tế.
- Cơ chế bảo mật: Đăng nhập/Đăng ký, mã hóa mật khẩu, phân quyền (User chỉ xóa được bài của mình).

---

# III. KẾ HOẠCH THỰC HIỆN ĐỀ TÀI

| Tuần | Nội dung công việc | Thời gian dự kiến | Ghi chú |
| :--- | :--- | :--- | :--- |
| **1** | **Khởi động:** Nhận đề tài; Phân tích yêu cầu; Lựa chọn công nghệ (Flutter + Node.js); Hoàn thiện đề cương chi tiết. | .../... - .../... | Hoàn thành |
| **2** | **Phân tích & Thiết kế:** Nghiên cứu yêu cầu người dùng; Thiết kế CSDL MongoDB; Thiết kế UI/UX App. | .../... - .../... | Hoàn thành |
| **3** | **Xây dựng Backend:** Cài đặt Node.js Server; Viết API CRUD Báo cáo; Kết nối Database & Cloudinary. | .../... - .../... | Hoàn thành |
| **4** | **Xây dựng Mobile App (Map):** Tích hợp OpenStreetMap; Xử lý định vị GPS; Hiển thị Marker lên bản đồ. | .../... - .../... | Hoàn thành |
| **5** | **Phát triển tính năng chính:** Chức năng Gửi báo cáo (kèm ảnh); Chức năng SOS khẩn cấp; Xử lý Marker chồng lấn. | .../... - .../... | Hoàn thành |
| **6** | **Bảo mật & Tài khoản:** API Đăng ký/Đăng nhập; Mã hóa mật khẩu; Phân quyền người dùng (JWT). | .../... - .../... | **Đang thực hiện** |
| **7** | **Nâng cao & Kiểm thử:** Tích hợp API Thời tiết; Bộ lọc bản đồ; Test toàn bộ hệ thống (Unit Test, UI Test). | .../... - .../... | Dự kiến |
| **8** | **Tổng kết:** Viết báo cáo tốt nghiệp; Làm slide thuyết trình; Đóng gói sản phẩm. | .../... - .../... | Dự kiến |

---

# IV. HƯỚNG DẪN CÀI ĐẶT VÀ CHẠY DỰ ÁN

Để chạy được hệ thống này, bạn cần cài đặt cả **Server** (Backend) và **App** (Frontend).

### 1. Yêu cầu hệ thống
- Node.js (v14+)
- Flutter SDK (v3.0+)
- MongoDB (Atlas hoặc Local)

### 2. Cài đặt Server (Backend)

1.  Mở terminal tại thư mục `server`:
    ```bash
    cd server
    npm install
    ```

2.  Cấu hình file `.env` (tạo mới nếu chưa có) trong thư mục `server`:
    ```env
    PORT=3000
    MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/disaster_db
    JWT_SECRET=your_secret_key
    CLOUDINARY_CLOUD_NAME=xxx
    CLOUDINARY_API_KEY=xxx
    CLOUDINARY_API_SECRET=xxx
    ```

3.  Chạy Server:
    ```bash
    node index.js
    ```
    *(Server sẽ chạy tại `http://localhost:3000`)*

### 3. Cài đặt Mobile App (Flutter)

1.  Mở terminal tại thư mục `disaster_app`:
    ```bash
    cd disaster_app
    flutter pub get
    ```

2.  **Cấu hình IP máy chủ:**
    * Tìm file `lib/features/map/services/disaster_service.dart` và `lib/features/auth/services/auth_service.dart`.
    * Đổi `localhost` thành địa chỉ IPv4 LAN của máy tính (VD: `192.168.1.X`).
    ```dart
    static const String baseUrl = '[http://192.168.1.5:3000/api](http://192.168.1.5:3000/api)';
    ```

3.  Chạy ứng dụng lên máy ảo hoặc thiết bị thật:
    ```bash
    flutter run
    ```

---

## 👨‍💻 Tác giả
* **Sinh viên:** Trần Duy Vũ
* **Lớp:** CNT3
* **Khoa:** Công nghệ Thông tin - Trường ĐH Nguyễn Trãi
* **GVHD:** Thầy Đinh Công Tùng