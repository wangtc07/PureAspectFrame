import SwiftUI
import SwiftData

/// 【底欄】分頁視圖
public struct FooterTabView: View {
    @Binding var footerSettings: FooterSettings
    @Binding var exifMetadata: ExifMetadata
    
    @Query private var manualLenses: [ManualLens]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddLensSheet: Bool = false
    @State private var showingLensPickerSheet: Bool = false
    @State private var newLensName: String = ""
    @State private var newLensFocal: String = "50"
    @State private var newLensAperture: String = "1.4"
    
    public init(
        footerSettings: Binding<FooterSettings>,
        exifMetadata: Binding<ExifMetadata>
    ) {
        self._footerSettings = footerSettings
        self._exifMetadata = exifMetadata
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. 底欄總開關與字體大小
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("顯示照片底欄")
                                .font(.headline)
                            Text("在相片下方呈現品牌 Logo 與 EXIF 拍攝參數")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $footerSettings.isEnabled)
                            .labelsHidden()
                    }
                    
                    if footerSettings.isEnabled {
                        Divider().opacity(0.3)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("文字大小比例")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f%%", footerSettings.fontSizeScale * 100))
                                    .font(.caption.monospaced())
                            }
                            Slider(value: $footerSettings.fontSizeScale, in: 0.015...0.038)
                        }
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                
                if footerSettings.isEnabled {
                    // 2. 當前底欄啟用之積木 (左右排列與長按互動)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("底欄已啟用積木")
                                .font(.headline)
                            Spacer()
                            Text("點選移除 · 長按換鏡頭")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if footerSettings.activeItems.isEmpty {
                            Text("尚未加入任何底欄積木，請由下方倉庫點選加入")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(footerSettings.activeItems) { item in
                                        HStack(spacing: 6) {
                                            Text(item.rawValue)
                                                .font(.caption.bold())
                                            
                                            // 移除按鈕
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    footerSettings.activeItems.removeAll { $0 == item }
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.primary.opacity(0.08))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .strokeBorder(
                                                            item == .lens ? Color.orange.opacity(0.7) : Color.primary.opacity(0.2),
                                                            style: StrokeStyle(lineWidth: 1.2, dash: [4, 2])
                                                        )
                                                }
                                        }
                                        .contextMenu {
                                            if item == .lens {
                                                Button("選擇既有手動老鏡...") {
                                                    showingLensPickerSheet = true
                                                }
                                                Button("新增自訂手動鏡頭...") {
                                                    showingAddLensSheet = true
                                                }
                                            }
                                            Button("從底欄移除", role: .destructive) {
                                                footerSettings.activeItems.removeAll { $0 == item }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                    
                    // 3. 下方倉庫（僅顯示未被使用的資訊）
                    VStack(alignment: .leading, spacing: 10) {
                        Text("未使用的資訊積木（點選加入底欄）")
                            .font(.headline)
                        
                        let unused = footerSettings.availableUnusedItems
                        if unused.isEmpty {
                            Text("所有積木皆已加入底欄")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(unused) { item in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            footerSettings.activeItems.append(item)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle")
                                                .font(.caption2)
                                            Text(item.rawValue)
                                                .font(.caption.bold())
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                        .background {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.primary.opacity(0.05))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                    
                    // 4. 自訂文字輸入（若有加入 customText）
                    if footerSettings.activeItems.contains(.customText) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自訂簽名 / 水印文字")
                                .font(.subheadline.bold())
                            TextField("請輸入簽名文字", text: $footerSettings.customText)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingAddLensSheet) {
            NavigationStack {
                Form {
                    Section("鏡頭資訊") {
                        TextField("鏡頭名稱 (如 Noctilux 50/0.95)", text: $newLensName)
                        TextField("焦距 (mm)", text: $newLensFocal)
                            .keyboardType(.numberPad)
                        TextField("最大光圈 (如 1.4 或 0.95)", text: $newLensAperture)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle("新增手動鏡頭")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { showingAddLensSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("儲存並套用") {
                            let focal = Double(newLensFocal) ?? 50.0
                            let aperture = Double(newLensAperture) ?? 1.4
                            let lens = ManualLens(name: newLensName, focalLength: focal, maxAperture: aperture)
                            modelContext.insert(lens)
                            exifMetadata.lensModel = lens.displayTitle
                            exifMetadata.focalLength = focal
                            exifMetadata.fNumber = aperture
                            showingAddLensSheet = false
                        }
                        .disabled(newLensName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingLensPickerSheet) {
            NavigationStack {
                List {
                    if manualLenses.isEmpty {
                        Text("尚未建立任何手動鏡頭")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manualLenses) { lens in
                            Button {
                                exifMetadata.lensModel = lens.displayTitle
                                exifMetadata.focalLength = lens.focalLength
                                exifMetadata.fNumber = lens.maxAperture
                                showingLensPickerSheet = false
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(lens.name).font(.headline)
                                    Text("\(Int(lens.focalLength))mm  f/\(lens.maxAperture)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("選擇手動老鏡")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("關閉") { showingLensPickerSheet = false }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("新增") {
                            showingLensPickerSheet = false
                            showingAddLensSheet = true
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
