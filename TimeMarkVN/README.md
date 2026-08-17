# TimeMark VN V5

V5 = bản nâng cấp từ prototype sang hướng sản phẩm thương mại.

## Mới trong V5
- StoreKit 2
- Pro entitlement
- 3 Product ID mẫu: monthly / yearly / lifetime
- Purchase
- Restore purchases
- Transaction listener
- Paywall
- Khóa Batch Export nếu chưa Pro
- Giới hạn Free template ở 3
- Chia sẻ ảnh bằng iOS Share Sheet
- Chia sẻ ảnh từ Gallery
- Camera zoom native tới mức thiết bị cho phép
- Giữ các tính năng V4: GPS, địa chỉ, weather, map, watermark editor, kéo watermark, logo, preset, template.

## Product IDs cần tạo trong App Store Connect
- com.timemarkvn.pro.monthly
- com.timemarkvn.pro.yearly
- com.timemarkvn.pro.lifetime

Tên và giá chỉ là ví dụ; cần cấu hình sản phẩm thật trong App Store Connect.

## Test StoreKit
Có thể tạo StoreKit Configuration File trong Xcode để test local trước khi đưa lên App Store Connect.

## Chạy
Tạo iOS App SwiftUI, iOS 17+, thêm các file Swift vào target.
Kiểm tra Bundle Identifier phải khớp Product ID prefix bạn dùng.

Camera/GPS/Photos cần test trên iPhone thật.
