import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    @EnvironmentObject private var authVM: AuthViewModel

    // เก็บรูปที่เลือกแบบชั่วคราว (สำหรับแสดงทันที)
    @State private var pickedItem: PhotosPickerItem? = nil
    @State private var localImageData: Data? = nil

    var body: some View {
        NavigationStack {
            Form {
                // รูปโปรไฟล์
                Section("รูปโปรไฟล์") {
                    HStack(spacing: 16) {
                        ProfileAvatarView(
                            remoteURL: vm.user?.photoURL,
                            localImageData: localImageData
                        )
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(vm.user?.displayName ?? "User")
                                .font(.headline)
                            Text("@\(vm.user?.username ?? "-")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        PhotosPicker(selection: $pickedItem, matching: .images) {
                            if vm.isUploading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Label("เปลี่ยนรูป", systemImage: "photo.on.rectangle")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .disabled(vm.isUploading)
                    }
                    .onChange(of: pickedItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                // แสดงทันทีจาก local
                                localImageData = data
                                // อัปโหลดจริง
                                await vm.uploadProfileImage(data)
                                // อัปโหลดเสร็จ เคลียร์ local preview (ให้ใช้รูปจาก remote URL)
                                localImageData = nil
                            }
                        }
                    }
                }

                Section("ข้อมูลผู้ใช้") {
                    if let u = vm.user {
                        LabeledContent("ชื่อที่แสดง", value: u.displayName)
                        LabeledContent("Username", value: "@\(u.username)")
                        LabeledContent("All-Time High", value: "\(u.allTimeHigh)")
                        LabeledContent("Streak", value: "\(u.streak) วัน")
                    } else {
                        ProgressView("กำลังโหลด...")
                            .tint(.white)
                    }
                }

                Section("การแจ้งเตือนรายวัน") {
                    if vm.notificationAuthorized {
                        DatePicker("เวลา", selection: $vm.scheduledTime, displayedComponents: .hourAndMinute)
                            .tint(.white)
                        HStack {
                            Button {
                                Task { await vm.scheduleDailyNotification() }
                            } label: {
                                Label("ตั้งค่าแจ้งเตือน", systemImage: "bell.badge.fill")
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)

                            Button(role: .destructive) {
                                Task { await vm.cancelNotifications() }
                            } label: {
                                Label("ยกเลิก", systemImage: "bell.slash.fill")
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.9))
                        }
                    } else {
                        Text("แอปยังไม่ได้รับอนุญาตให้แจ้งเตือน")
                            .foregroundStyle(.black)
                        HStack {
                            Button {
                                Task { await vm.requestNotificationPermission() }
                            } label: {
                                Label("ขออนุญาตแจ้งเตือน", systemImage: "bell.badge.fill")
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)

                            Button {
                                vm.openSettings()
                            } label: {
                                Label("เปิด Settings", systemImage: "gear")
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.9))
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AccentColor").ignoresSafeArea())
            .navigationTitle("Profile")
            .onAppear { vm.load() }
        }
        .tint(Color("AccentColor"))
    }
}

private struct ProfileAvatarView: View {
    let remoteURL: URL?
    let localImageData: Data?

    var body: some View {
        ZStack {
            if let data = localImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else if let url = remoteURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 72, height: 72)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white.opacity(0.85))
            .padding(6)
    }
}
