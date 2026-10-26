# Hệ thống Quản lý Đặt lịch Phòng khám và Xét nghiệm – Môi trường Database (Docker & PostgreSQL)

> **Đề tài Nhóm 10 – Trường Đại học Hoa Sen**  
> **Công nghệ toàn hệ thống:** Flutter/Dart (Frontend) • REST API (Backend) • PostgreSQL 16 trên Docker Compose (Database dùng chung)

Thư mục này cung cấp môi trường cơ sở dữ liệu **PostgreSQL (`postgres:16.8-bookworm`)** dùng chung cho nhóm phát triển thông qua **Docker Compose**, được thiết kế bám sát 100% đặc tả trong **Báo cáo Chuyên đề 2, 3 và 4**.

---

## 1. Yêu cầu cài đặt
- Hệ điều hành: Windows 10/11 (64-bit, đã bật WSL 2) hoặc macOS / Linux.
- Đã cài đặt và mở **Docker Desktop** ở trạng thái **`Engine running`**.
- Kiểm tra phiên bản Docker trên PowerShell:
  ```powershell
  docker --version
  docker compose version
  ```
- Cổng **`5432`** trên máy local đang trống (hoặc có thể đổi cổng ngoài qua biến `POSTGRES_PORT` trong file `.env`). Lệnh kiểm tra nhanh xung đột cổng trên PowerShell:
  ```powershell
  Get-NetTCPConnection -LocalPort 5432 -ErrorAction SilentlyContinue
  ```
  *(Nếu không hiện dòng kết quả nào nghĩa là cổng `5432` hoàn toàn trống).*

---

## 2. Cấu trúc thư mục

```text
.
├── database/
│   ├── 01_schema.sql      # Khởi tạo 9 bảng, khóa (PK/FK/UK), CHECK và các Index theo Chuyên đề 2
│   └── 02_seed_data.sql   # Dữ liệu mẫu giả lập & các giao dịch (Transaction) đặt lịch minh họa
├── .env.example           # File mẫu cấu hình biến môi trường (được phép commit lên Git)
├── .env                   # File cấu hình thực tế trên máy local (TUYỆT ĐỐI KHÔNG commit lên Git)
├── .gitignore             # Loại trừ file .env và các tệp nhạy cảm khỏi Git
├── compose.yaml           # Cấu hình Docker Compose cho PostgreSQL (service: db, healthcheck, volume)
└── README.md              # Tài liệu hướng dẫn cài đặt, vận hành, kết nối và kịch bản demo
```

### Giải thích các lựa chọn kỹ thuật trong `compose.yaml`
- **Image `postgres:16.8-bookworm` (Không dùng tag `latest`):** Ghim cố định nhánh ổn định dài hạn PostgreSQL 16 trên nền Debian Bookworm giúp mọi thành viên trong nhóm chạy chính xác cùng một phiên bản, tránh lỗi lệch định dạng dữ liệu giữa các máy và hỗ trợ bảng mã tiếng Việt (`UTF-8`) ổn định.
- **Giới hạn cổng Local (`127.0.0.1:${POSTGRES_PORT:-5432}:5432`):** Chỉ cho phép kết nối từ chính máy local, ngăn các thiết bị lạ trong cùng mạng Wi-Fi công cộng truy cập vào cơ sở dữ liệu phát triển.
- **Healthcheck (`pg_isready`):** Tự động kiểm tra định kỳ xem tiến trình PostgreSQL bên trong container đã thực sự sẵn sàng nhận câu lệnh SQL của `clinic_booking` hay chưa.
- **Named Volume (`postgres_data`):** Lưu trữ dữ liệu độc lập với vòng đời container.

---

## 3. Hướng dẫn thiết lập lần đầu (PowerShell)

Khi thành viên mới clone dự án về máy, mở **PowerShell** tại thư mục gốc của project và chạy lần lượt 4 bước sau:

1. **Sao chép file `.env.example` thành `.env`:**
   ```powershell
   Copy-Item .env.example .env
   ```
2. **Cấu hình mật khẩu local:**
   Mở file `.env` vừa tạo và đặt mật khẩu cho biến `POSTGRES_PASSWORD` (theo thống nhất nội bộ của nhóm; không ghi mật khẩu thật vào `README.md` hay code commit lên Git).
3. **Khởi động container PostgreSQL chạy ngầm:**
   ```powershell
   docker compose up -d
   ```
4. **Kiểm tra trạng thái container (đợi trạng thái chuyển sang `healthy`):**
   ```powershell
   docker compose ps
   ```

> **Lưu ý khi khởi tạo lần đầu:**  
> Nhờ ánh xạ `./database:/docker-entrypoint-initdb.d:ro` trong `compose.yaml`, ở lần đầu tiên chạy `docker compose up -d` khi volume `postgres_data` còn trống, PostgreSQL sẽ **tự động thực thi** theo thứ tự tên file: `01_schema.sql` -> `02_seed_data.sql`. Thành viên mới sẽ có ngay đủ **9 bảng** và **dữ liệu mẫu** mà không cần chạy SQL thủ công.

---

## 4. Các lệnh quản lý thường dùng (PowerShell)

- **Xem nhật ký (log) hoạt động của PostgreSQL:**
  ```powershell
  docker compose logs -f db
  ```
  *(Nhấn `Ctrl + C` để thoát chế độ theo dõi log).*

- **Mở trình giao tiếp SQL (`psql`) trực tiếp bên trong container:**
  ```powershell
  docker compose exec db psql -U clinic_admin -d clinic_booking
  ```
  *(Bên trong `psql`: gõ `\dt` xem danh sách bảng, `\d ten_bang` xem cấu trúc bảng, `\q` để thoát).*

- **Tạm dừng container (giữ nguyên container và dữ liệu):**
  ```powershell
  docker compose stop
  ```

- **Bật lại container đã tạm dừng:**
  ```powershell
  docker compose start
  ```

- **Gỡ bỏ container và network (VẪN GIỮ NGUYÊN dữ liệu trong Named Volume `postgres_data`):**
  ```powershell
  docker compose down
  ```

---

## 5. Thông tin kết nối dành cho Backend (REST API) & Công cụ GUI

Ứng dụng Flutter/Dart **không kết nối trực tiếp** vào PostgreSQL mà giao tiếp thông qua Backend REST API. Khi cấu hình chuỗi kết nối ở phía Backend, địa chỉ `Host` thay đổi tùy theo cách chạy Backend:

| Trường hợp chạy Backend | `DB_HOST` | `DB_PORT` | Chuỗi kết nối mẫu (Connection URI) |
| :--- | :--- | :--- | :--- |
| **1. Backend chạy trực tiếp trên máy Windows (ngoài Docker)** | `localhost` *(hoặc `127.0.0.1`)* | Giá trị `POSTGRES_PORT` trong `.env` *(mặc định `5432`)* | `postgresql://clinic_admin:<PASSWORD>@127.0.0.1:5432/clinic_booking` |
| **2. Backend đóng gói chạy trong Container thuộc cùng `compose.yaml`** | **`db`** *(tên service trong `compose.yaml`)* | `5432` *(cổng nội bộ container)* | `postgresql://clinic_admin:<PASSWORD>@db:5432/clinic_booking` |

*(Nếu dùng công cụ giao diện như DBeaver, pgAdmin hoặc tiện ích Database trong VS Code/Antigravity trên máy Windows: kết nối theo Trường hợp 1 với `Host = 127.0.0.1`, `Port = 5432`, `Database = clinic_booking`, `User = clinic_admin`).*

---

## 6. Thiết kế 9 bảng dữ liệu (Bám sát Báo cáo Chuyên đề 2)

Phạm vi nghiệp vụ: Một phòng khám; người dùng đặt lịch cho bản thân; dịch vụ khám (`examination`) hoặc xét nghiệm (`test`); tài nguyên là phòng khám (`consultation_room`) hoặc bàn lấy mẫu (`sampling_station`). Không bao gồm bác sĩ, thanh toán, bệnh án, đơn thuốc hoặc kết quả xét nghiệm.

| Phân hệ | Tên bảng | Điểm nhấn khóa & ràng buộc chính |
| :--- | :--- | :--- |
| **1. Auth** | `users` | `PK(id)`, `UNIQUE(email)`, `status IN ('active', 'locked')`, chỉ lưu `password_hash`. |
| **1. Auth** | `roles` | `PK(id)`, `UNIQUE(code)` (`admin`, `patient`). |
| **1. Auth** | `user_roles` | `PK ghép (user_id, role_id)`, không có cột `id`, `FK` tới `users` và `roles`. |
| **2. Patient** | `patients` | `PK(id)`, `FK` + `UNIQUE(user_id)` tới `users(id)`, chỉ `date_of_birth` cho phép `NULL`. |
| **3. Clinic** | `services` | `PK(id)`, `UNIQUE(code)`, `kind IN ('examination', 'test')`, `price >= 0`, ngừng dùng qua `is_active = false`. |
| **3. Clinic** | `resources` | `PK(id)`, `resource_type IN ('consultation_room', 'sampling_station')`, ngừng dùng qua `is_active = false`. |
| **4. Booking** | `slots` | `PK(id)`, `UNIQUE(resource_id, starts_at)`, dài đúng `30 phút` (`ends_at = starts_at + 30m`), bắt đầu ở phút `:00` hoặc `:30`. |
| **4. Booking** | `appointments` | `PK(id)`, `UNIQUE(patient_id, request_id)` chống gửi lặp, `price_snapshot` giữ giá lúc đặt, `status IN ('pending', 'confirmed', 'completed', 'cancelled')`, Partial Unique Index `uq_slot_not_cancelled`. |
| **4. Booking** | `appointment_history` | `PK(id)`, `FK` tới `appointments` và `users(actor_user_id)`, ghi cùng **Transaction** với thay đổi trên `appointments`. |

---

## 7. Cơ chế lưu trữ Volume và Quy trình cập nhật SQL có kiểm soát

1. **Vì sao sửa file trong `database/` không tự chạy lại khi khởi động lại container?**
   - Theo cơ chế an toàn của PostgreSQL Official Image, các file trong `/docker-entrypoint-initdb.d` (`./database`) **chỉ tự động chạy khi thư mục dữ liệu của Volume hoàn toàn trống**.
   - Ở các lần bật lại sau, PostgreSQL phát hiện đã có dữ liệu nên sẽ bỏ qua bước khởi tạo (`Skipping initialization`) để bảo vệ dữ liệu hiện hành.

2. **Cách cập nhật khi sửa/bổ sung SQL sau lần khởi tạo đầu (Không mặc định xóa Volume):**
   - Tạo một file SQL cập nhật mới có đánh số thứ tự tiếp theo trong `database/` (ví dụ: `database/03_alter_or_seed.sql`).
   - Chạy có kiểm soát trực tiếp file mới đó vào database đang hoạt động:
     ```powershell
     docker compose exec db psql -v ON_ERROR_STOP=1 -P pager=off -U clinic_admin -d clinic_booking -f /docker-entrypoint-initdb.d/03_alter_or_seed.sql
     ```

3. **Nguyên tắc an toàn dữ liệu:**
   - **Không** chạy lệnh xóa volume (`docker compose down -v` hoặc `docker volume rm`) khi chưa giải thích rõ và được các thành viên thống nhất, vì việc xóa volume sẽ làm mất toàn bộ dữ liệu đang thử nghiệm trên máy local.

---

## 8. Phân biệt kiểm tra Unique Index và kiểm thử chống đặt trùng đồng thời

- **Kiểm tra Unique Index trên `psql` (Tuần tự):** Chạy thử câu lệnh `INSERT`/`UPDATE` thứ hai trùng `slot_id` đang hiệu lực để xác minh ràng buộc `uq_slot_not_cancelled` hoạt động và Transaction tự `ROLLBACK` giữ nguyên lịch cũ khi đổi vào giờ kín.
- **Kiểm thử đầy đủ chống đặt trùng đồng thời (Concurrent Testing tại tầng API + DB):** Khi tích hợp Backend REST API, nhóm cần gửi nhiều HTTP request đồng thời vào cùng một `slot_id` (hoặc hai khung giờ giao nhau của cùng một bệnh nhân) để kiểm chứng đầy đủ: khóa hàng (`SELECT ... FOR UPDATE`), thứ tự khóa chống *Deadlock*, xử lý `request_id` (idempotency), và ánh xạ lỗi vi phạm ràng buộc sang mã phản hồi `HTTP 409 Conflict`.

---

## 9. Kịch bản Demo ngắn 5 bước (Báo cáo & Kiểm tra nhanh)

Mở **PowerShell** tại thư mục gốc của dự án và chạy lần lượt 5 bước sau:

### Bước 1: Khởi động PostgreSQL bằng Docker Compose
```powershell
docker compose up -d
```

### Bước 2: Kiểm tra trạng thái container (`healthy`) và nhật ký
```powershell
docker compose ps
docker compose logs --tail 15 db
```

### Bước 3: Kết nối PostgreSQL, kiểm tra phiên bản, database và tài khoản
```powershell
docker compose exec db psql -P pager=off -U clinic_admin -d clinic_booking -c "SELECT version(); SELECT current_database() AS db, current_user AS tai_khoan, current_setting('TIMEZONE') AS mui_gio;"
```

### Bước 4: Xem danh sách 9 bảng, dữ liệu mẫu và chứng minh chặn đặt trùng
```powershell
# 4.1. Liệt kê đủ 9 bảng
docker compose exec db psql -P pager=off -U clinic_admin -d clinic_booking -c "\dt"

# 4.2. Xem danh sách lịch hẹn kèm tên bệnh nhân, dịch vụ và giá snapshot
docker compose exec db psql -P pager=off -U clinic_admin -d clinic_booking -c "SELECT a.id, p.full_name, s.name AS service_name, t.starts_at, a.status, a.price_snapshot FROM appointments a JOIN patients p ON p.id = a.patient_id JOIN slots t ON t.id = a.slot_id JOIN services s ON s.id = t.service_id ORDER BY a.id;"

# 4.3. Thử đặt trùng vào slot_id = 2 (đang có lịch confirmed) -> Bị chặn bởi uq_slot_not_cancelled
docker compose exec db psql -P pager=off -U clinic_admin -d clinic_booking -c "INSERT INTO appointments (patient_id, slot_id, status, request_id, price_snapshot) VALUES (2, 2, 'pending', '99999999-9999-4999-8999-999999999999', 150000);"
```

### Bước 5: Chứng minh dữ liệu được giữ lại bền vững qua Volume khi tạo lại container
```powershell
docker compose down
docker compose up -d
Start-Sleep -Seconds 5
docker compose exec db psql -P pager=off -U clinic_admin -d clinic_booking -c "SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM services) AS services, (SELECT COUNT(*) FROM slots) AS slots, (SELECT COUNT(*) FROM appointments) AS appointments, (SELECT COUNT(*) FROM appointment_history) AS history;"
```
*(Kết quả trả về nguyên vẹn `users=4, services=4, slots=6, appointments=4, history=8` sau khi gỡ và tạo lại container).*