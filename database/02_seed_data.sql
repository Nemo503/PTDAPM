-- =============================================================================
-- CHUYÊN ĐỀ 2: DỮ LIỆU MẪU GIẢ LẬP CHO MÔI TRƯỜNG PHÁT TRIỂN & DEMO
-- File: database/02_seed_data.sql
-- Lưu ý: Toàn bộ thông tin dưới đây là dữ liệu giả phục vụ học tập & kiểm thử
-- =============================================================================

SET TIME ZONE 'Asia/Ho_Chi_Minh';

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. VAI TRÒ (roles) & TÀI KHOẢN (users) & PHÂN QUYỀN (user_roles)
-- -----------------------------------------------------------------------------
INSERT INTO roles (id, code, name) VALUES
    (1, 'admin', 'Quản trị viên phòng khám'),
    (2, 'patient', 'Người bệnh đặt lịch');

-- password_hash chỉ lưu chuỗi băm giả lập minh họa, tuyệt đối không lưu mật khẩu rõ
INSERT INTO users (id, email, password_hash, status, created_at) VALUES
    (1, 'admin.demo@clinic.example.test',     '$2b$12$DemoFakeBcryptHashForAdminAccount00000000000000000001', 'active', '2026-10-01 08:00:00+07'),
    (2, 'patient01.demo@clinic.example.test', '$2b$12$DemoFakeBcryptHashForPatientOne0000000000000000000002', 'active', '2026-10-05 09:00:00+07'),
    (3, 'patient02.demo@clinic.example.test', '$2b$12$DemoFakeBcryptHashForPatientTwo0000000000000000000003', 'active', '2026-10-06 10:15:00+07'),
    (4, 'locked.demo@clinic.example.test',    '$2b$12$DemoFakeBcryptHashForLockedUser0000000000000000000004', 'locked', '2026-10-07 14:00:00+07');

INSERT INTO user_roles (user_id, role_id) VALUES
    (1, 1), -- admin.demo -> admin
    (2, 2), -- patient01.demo -> patient
    (3, 2), -- patient02.demo -> patient
    (4, 2); -- locked.demo -> patient

-- -----------------------------------------------------------------------------
-- 2. HỒ SƠ BỆNH NHÂN (patients) - Đặt lịch cho bản thân (Admin không cần hồ sơ)
-- -----------------------------------------------------------------------------
INSERT INTO patients (id, user_id, full_name, date_of_birth, phone) VALUES
    (1, 2, 'Nguyễn Minh An (Dữ liệu giả)', '1999-04-15', '0900000101'),
    (2, 3, 'Trần Thu Hà (Dữ liệu giả)',    NULL,         '0900000102');

-- -----------------------------------------------------------------------------
-- 3. DANH MỤC DỊCH VỤ (services) & TÀI NGUYÊN (resources)
-- -----------------------------------------------------------------------------
INSERT INTO services (id, code, name, kind, price, is_active) VALUES
    (1, 'KHAM_TQ',      'Khám nội tổng quát',        'examination', 150000, TRUE),
    (2, 'KHAM_TMH',     'Khám Tai - Mũi - Họng',     'examination', 180000, TRUE),
    (3, 'XN_MAU',       'Xét nghiệm máu tổng quát',  'test',        100000, TRUE),
    (4, 'XN_SINH_HOA',  'Xét nghiệm sinh hóa máu',   'test',        250000, FALSE); -- Minh họa dịch vụ đã ngừng cung cấp

INSERT INTO resources (id, name, resource_type, is_active) VALUES
    (1, 'Phòng khám Nội 101',                  'consultation_room', TRUE),
    (2, 'Phòng khám Chuyên khoa 102',          'consultation_room', TRUE),
    (3, 'Bàn lấy mẫu Xét nghiệm A1',           'sampling_station',  TRUE),
    (4, 'Bàn lấy mẫu Xét nghiệm A2 (Bảo trì)', 'sampling_station',  FALSE);

-- -----------------------------------------------------------------------------
-- 4. KHUNG GIỜ 30 PHÚT (slots) - Bắt đầu ở phút 00 hoặc 30
-- -----------------------------------------------------------------------------
INSERT INTO slots (id, service_id, resource_id, starts_at, ends_at, is_open) VALUES
    -- Khung giờ trong quá khứ (phục vụ minh họa lịch hẹn đã hoàn tất 'completed')
    (1, 1, 1, '2026-10-20 08:00:00+07', '2026-10-20 08:30:00+07', TRUE),

    -- Các khung giờ tương lai tại Phòng khám Nội 101 (service KHAM_TQ)
    (2, 1, 1, '2026-11-10 08:00:00+07', '2026-11-10 08:30:00+07', TRUE), -- Có 1 lịch hủy + 1 lịch confirmed
    (3, 1, 1, '2026-11-10 08:30:00+07', '2026-11-10 09:00:00+07', TRUE), -- Đang có lịch pending
    (4, 1, 1, '2026-11-10 09:00:00+07', '2026-11-10 09:30:00+07', TRUE), -- Còn trống (để test đặt/đổi lịch)

    -- Các khung giờ tương lai tại Bàn lấy mẫu A1 (service XN_MAU)
    (5, 3, 3, '2026-11-10 08:00:00+07', '2026-11-10 08:30:00+07', TRUE), -- Còn trống (khác tài nguyên nên cùng 08:00 hợp lệ)
    (6, 3, 3, '2026-11-10 08:30:00+07', '2026-11-10 09:00:00+07', FALSE); -- Khung giờ đang đóng (is_open = false)

COMMIT;

-- -----------------------------------------------------------------------------
-- 5. GIAO DỊCH ĐẶT LỊCH & GHI LỊCH SỬ TRONG CÙNG TRANSACTION (Mục 5.3)
-- -----------------------------------------------------------------------------

-- Giao dịch A: Lịch hẹn #1 đã hoàn tất trong quá khứ (pending -> confirmed -> completed)
BEGIN;
INSERT INTO appointments (id, patient_id, slot_id, status, request_id, price_snapshot, created_at)
VALUES (1, 1, 1, 'completed', '11111111-1111-4111-8111-111111111101', 150000, '2026-10-18 10:00:00+07');

INSERT INTO appointment_history (appointment_id, actor_user_id, old_status, new_status, note, created_at) VALUES
    (1, 2, NULL,        'pending',   'Bệnh nhân tạo yêu cầu đặt lịch khám', '2026-10-18 10:00:00+07'),
    (1, 1, 'pending',   'confirmed', 'Quản trị viên xác nhận lịch hẹn',     '2026-10-18 11:00:00+07'),
    (1, 1, 'confirmed', 'completed', 'Hoàn tất ca khám tại Phòng 101',      '2026-10-20 08:35:00+07');
COMMIT;

-- Giao dịch B: Bệnh nhân #2 từng đặt slot #2 nhưng sau đó đã hủy ('cancelled')
BEGIN;
INSERT INTO appointments (id, patient_id, slot_id, status, request_id, price_snapshot, created_at)
VALUES (2, 2, 2, 'cancelled', '22222222-2222-4222-8222-222222222201', 150000, '2026-10-25 09:00:00+07');

INSERT INTO appointment_history (appointment_id, actor_user_id, old_status, new_status, note, created_at) VALUES
    (2, 3, NULL,      'pending',   'Bệnh nhân tạo lịch khám',                    '2026-10-25 09:00:00+07'),
    (2, 3, 'pending', 'cancelled', 'Bệnh nhân chủ động hủy lịch trước giờ hẹn', '2026-10-25 15:00:00+07');
COMMIT;

-- Giao dịch C: Bệnh nhân #1 đặt vào đúng slot #2 (thành công vì lịch #2 trước đó đã 'cancelled')
BEGIN;
SELECT id FROM patients WHERE id = 1 FOR UPDATE;
SELECT id FROM slots WHERE id = 2 AND is_open = TRUE FOR UPDATE;

INSERT INTO appointments (id, patient_id, slot_id, status, request_id, price_snapshot, created_at)
VALUES (3, 1, 2, 'confirmed', '11111111-1111-4111-8111-111111111102', 150000, '2026-10-26 08:30:00+07');

INSERT INTO appointment_history (appointment_id, actor_user_id, old_status, new_status, note, created_at) VALUES
    (3, 2, NULL,      'pending',   'Bệnh nhân đặt lại khung giờ vừa trống', '2026-10-26 08:30:00+07'),
    (3, 1, 'pending', 'confirmed', 'Quản trị viên xác nhận lịch hẹn',       '2026-10-26 09:00:00+07');
COMMIT;

-- Giao dịch D: Bệnh nhân #2 đặt slot #3 đang chờ xác nhận ('pending')
BEGIN;
SELECT id FROM patients WHERE id = 2 FOR UPDATE;
SELECT id FROM slots WHERE id = 3 AND is_open = TRUE FOR UPDATE;

INSERT INTO appointments (id, patient_id, slot_id, status, request_id, price_snapshot, created_at)
VALUES (4, 2, 3, 'pending', '22222222-2222-4222-8222-222222222202', 150000, '2026-10-26 10:00:00+07');

INSERT INTO appointment_history (appointment_id, actor_user_id, old_status, new_status, note, created_at)
VALUES (4, 3, NULL, 'pending', 'Bệnh nhân gửi yêu cầu đặt lịch mới', '2026-10-26 10:00:00+07');
COMMIT;

-- -----------------------------------------------------------------------------
-- 6. ĐỒNG BỘ BỘ ĐẾM TỰ TĂNG (IDENTITY SEQUENCE) SAU KHI CHÈN ID MẪU
-- -----------------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE((SELECT MAX(id) FROM users), 1));
SELECT setval(pg_get_serial_sequence('roles', 'id'), COALESCE((SELECT MAX(id) FROM roles), 1));
SELECT setval(pg_get_serial_sequence('patients', 'id'), COALESCE((SELECT MAX(id) FROM patients), 1));
SELECT setval(pg_get_serial_sequence('services', 'id'), COALESCE((SELECT MAX(id) FROM services), 1));
SELECT setval(pg_get_serial_sequence('resources', 'id'), COALESCE((SELECT MAX(id) FROM resources), 1));
SELECT setval(pg_get_serial_sequence('slots', 'id'), COALESCE((SELECT MAX(id) FROM slots), 1));
SELECT setval(pg_get_serial_sequence('appointments', 'id'), COALESCE((SELECT MAX(id) FROM appointments), 1));
SELECT setval(pg_get_serial_sequence('appointment_history', 'id'), COALESCE((SELECT MAX(id) FROM appointment_history), 1));