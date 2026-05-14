import SwiftUI

struct AddProductSheet: View {
    
    @EnvironmentObject var appState: AppState
    @Binding var isShowingSheet: Bool
    var routineId: String
    @State private var selectedProduct: Product? = nil
    @State private var selectedCategory: String = "اختر فئة"
    @State private var reminderDate: Date = Date()
    @State var isReminderEnabled = false
    @State private var searchText: String = ""
    @State private var isProductListOpen = false


//    let categories = ["Cleanser", "Serum", "Moisturizer", "Sunscreen"]
    let categories = ["غسول", "سيروم", "مرطب", "واقي شمس"]
//    let categories = Array(Set(appState.products.map { $0.category })).sorted() // come from the products


    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { isShowingSheet = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("اضافة منتج الى الروتين")
                            .font(.title2).bold()
                        Text("قم باضافة المنتجات الى روتينك")
                            .font(.subheadline).foregroundColor(.gray)
                    }
                    
                    // MARK: - Products Name (select the product) with search & image
                    VStack(alignment: .leading, spacing: 8) {
                        Text("اسم المنتج")
                            .font(.callout)
                            .foregroundColor(.black.opacity(0.8))
                        
                        Button(action: {
                            withAnimation {
                                isProductListOpen.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedProduct?.name ?? "اختر منتج")
                                    .foregroundColor(selectedProduct == nil ? .gray : .black)
                                Spacer()
                                Image(systemName: isProductListOpen ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        }
                        
                        if isProductListOpen {
                            VStack {
                                TextField("ابحث عن منتج...", text: $searchText)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(appState.products.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }, id: \.id) { product in
                                            Button(action: {
                                                selectedProduct = product
                                                isProductListOpen = false  
                                            }) {
                                                HStack(spacing: 12) {
                                                    if let urlString = product.imageURL, let url = URL(string: urlString) {
                                                        AsyncImage(url: url) { phase in
                                                            switch phase {
                                                            case .empty:
                                                                ProgressView()
                                                                    .frame(width: 40, height: 40)
                                                            case .success(let image):
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: 40, height: 40)
                                                                    .cornerRadius(5)
                                                            case .failure:
                                                                Rectangle()
                                                                    .fill(Color.gray.opacity(0.3))
                                                                    .frame(width: 40, height: 40)
                                                                    .cornerRadius(5)
                                                            @unknown default:
                                                                EmptyView()
                                                            }
                                                        }
                                                    } else {
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(width: 40, height: 40)
                                                            .cornerRadius(5)
                                                    }
                                                    
                                                    Text(product.name)
                                                        .foregroundColor(.black)
                                                    Spacer()
                                                    if selectedProduct?.id == product.id {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                            }
                                            .background(Color.white)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                    }

                    
                    // MARK: - Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("فئة المنتج")
                            .font(.callout)
                            .foregroundColor(.black)
                            
                        Picker("", selection: $selectedCategory) {
                            Text("اختر فئة").tag("اختر فئة").foregroundColor(.black)
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category).foregroundColor(.black)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        .labelsHidden()
                    }
                    
                    // MARK: - Reminder Time (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("حدد وقت التذكير (اختياري)")
                            .font(.callout)
                            .foregroundColor(.black.opacity(0.8))
                        
                        Toggle(isOn: $isReminderEnabled) {
                            Text("تفعيل التذكير")
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal)
                        
                        if isReminderEnabled {
                            HStack {
                                DatePicker("", selection: $reminderDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // MARK: - Add Button
            Button(action: addProduct) {
                Text("اضافة")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cornerRadius(12)
                    .foregroundColor(.black)
                    .background(Color.lightblue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                    )
            }
            .padding([.horizontal, .bottom], 20)
        }
    }
    
    // MARK: - Add Product
    func addProduct() {
        guard let product = selectedProduct else { return }
        guard selectedCategory != "اختر فئة" else { return } // ensure category selected
        
        let currentOrder = appState.routines.first(where: { $0.id == routineId })?.products.count ?? 0
        
        let newRoutineStep = RoutineStep(
            productName: product.name,
            category: selectedCategory,
            order: currentOrder + 1,
            reminderTime: isReminderEnabled ? reminderDate : nil
        )
        
        appState.addProductToRoutine(routineId: routineId, product: newRoutineStep)
        isShowingSheet = false
    }
}

#Preview {
    AddProductSheet(isShowingSheet: .constant(true), routineId: "morning")
        .environmentObject(AppState())
}

