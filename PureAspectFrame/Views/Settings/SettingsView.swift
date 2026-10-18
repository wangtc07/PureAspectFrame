import SwiftUI
import SwiftData

/// 設定頁面（參照 Apple iOS 系統設定風格：Inset Grouped、左側彩色圓角方塊圖示、明確 2 種儲存方式選擇）
public struct SettingsView: View {
    @AppStorage("default_storage_policy") private var defaultStoragePolicyRaw: String = StoragePolicy.settingsOnly.rawValue
    
    @Query(sort: \ManualLens.createdAt, order: .reverse) private var manualLenses: [ManualLens]
    @Query private var allArtworks: [ArtworkRecord]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddLens: Bool = false
    @State private var lensName: String = ""
    @State private var lensFocal: String = "50"
    @State private var lensAperture: String = "1.4"
    @State private var lensBrand: String = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // 1. 預設儲存方式（明確 2 種單選選項，Section Header 標註說明，徹底避免產生第 3 個無效選項列）
                Section {
                    Button {
                        defaultStoragePolicyRaw = StoragePolicy.fullImage.rawValue
                    } label: {
                        HStack {
                            SettingsRowLabel(
                                title: "保留輸出圖片",
                                subtitle: "完整寫入高解析點陣圖，不依賴原圖參照",
                                systemImage: "photo.fill",
                                iconColor: .blue
                            )
                            Spacer()
                            if defaultStoragePolicyRaw == StoragePolicy.fullImage.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        defaultStoragePolicyRaw = StoragePolicy.settingsOnly.rawValue
                    } label: {
                        HStack {
                            SettingsRowLabel(
                                title: "僅保留設定",
                                subtitle: "僅記錄畫布與相片參照，節省 98% 空間",
                                systemImage: "slider.horizontal.3",
                                iconColor: .purple
                            )
                            Spacer()
                            if defaultStoragePolicyRaw == StoragePolicy.settingsOnly.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("儲存方式")
                } footer: {
                    Text("「僅保留設定」只儲存相片參照與編輯設定，瀏覽或導出時即時重繪，可節省大幅設備儲存空間。")
                }
                
                // 2. 本機空間佔用統計
                Section {
                    let totalBytes = allArtworks.reduce(0) { $0 + $1.diskSizeBytes }
                    let totalMB = Double(totalBytes) / (1024 * 1024)
                    let fullImageCount = allArtworks.filter { $0.storagePolicy == .fullImage }.count
                    let settingsOnlyCount = allArtworks.filter { $0.storagePolicy == .settingsOnly }.count
                    
                    HStack {
                        SettingsRowLabel(
                            title: "歷史作品總數",
                            subtitle: nil,
                            systemImage: "square.stack.fill",
                            iconColor: .orange
                        )
                        Spacer()
                        Text("\(allArtworks.count) 件")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        SettingsRowLabel(
                            title: "完整存圖 / 僅存設定",
                            subtitle: nil,
                            systemImage: "internaldrive.fill",
                            iconColor: .indigo
                        )
                        Spacer()
                        Text("\(fullImageCount) / \(settingsOnlyCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        SettingsRowLabel(
                            title: "估計已佔用空間",
                            subtitle: nil,
                            systemImage: "chart.pie.fill",
                            iconColor: .teal
                        )
                        Spacer()
                        Text(String(format: "%.1f MB", totalMB))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("本機空間佔用")
                }
                
                // 3. 手動老鏡設備庫
                Section {
                    if manualLenses.isEmpty {
                        Text("尚未建立任何手動鏡頭")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manualLenses) { lens in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(lens.name)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    Text("\(Int(lens.focalLength))mm f/\(String(format: "%.1f", lens.maxAperture))")
                                        .font(.subheadline.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                if !lens.brand.isEmpty {
                                    Text(lens.brand)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(manualLenses[index])
                            }
                        }
                    }
                    
                    Button {
                        showingAddLens = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.green.gradient)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text("新增手動鏡頭")
                                .font(.body)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                } header: {
                    Text("手動老鏡設備庫")
                } footer: {
                    Text("手動鏡頭可在編輯器底欄長按鏡頭積木隨時切換與標註。")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmToolbarButton {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddLens) {
                NavigationStack {
                    Form {
                        Section("老鏡資訊") {
                            TextField("鏡頭名稱 (如 Summicron 35/2)", text: $lensName)
                            TextField("焦距 (mm)", text: $lensFocal)
                                .keyboardType(.numberPad)
                            TextField("最大光圈 (如 2.0)", text: $lensAperture)
                                .keyboardType(.decimalPad)
                            TextField("品牌 / 卡口 (選填)", text: $lensBrand)
                        }
                    }
                    .navigationTitle("新增手動老鏡")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            CloseToolbarButton { showingAddLens = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            ConfirmToolbarButton {
                                let f = Double(lensFocal) ?? 50
                                let a = Double(lensAperture) ?? 1.4
                                let lens = ManualLens(name: lensName, focalLength: f, maxAperture: a, brand: lensBrand)
                                modelContext.insert(lens)
                                lensName = ""
                                showingAddLens = false
                            }
                            .disabled(lensName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}
