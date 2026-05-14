import SwiftUI

// MARK: - Product Catalog View
struct ProductCatalogView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    // Enable search filtering
    private let useSearchFiltering = true
    
    var allProducts: [Product] {
        if useSearchFiltering && !searchText.isEmpty {
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty { return appState.products }
            return appState.products.filter { product in
                if product.name.localizedCaseInsensitiveContains(q) { return true }
                if product.brand.localizedCaseInsensitiveContains(q) { return true }
                if product.category.localizedCaseInsensitiveContains(q) { return true }
                if product.description.localizedCaseInsensitiveContains(q) { return true }
                if product.skinType.contains(where: { $0.localizedCaseInsensitiveContains(q) }) { return true }
                if product.ingredients.contains(where: { $0.localizedCaseInsensitiveContains(q) }) { return true }
                return false
            }
        } else {
            return appState.products
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header + search
            VStack(alignment: .leading, spacing: 12) {
                Text("اكتشف منتجات العناية بالبشرة")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("ابحث عن المنتجات، أو العلامة التجارية", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                )
                .cornerRadius(10)
            }
            .padding()
            
            // Products Grid
            ScrollView {
                if allProducts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("لا توجد منتجات")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(allProducts) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Product Card with Lazy Image Loading
struct ProductCard: View {
    let product: Product
    @State private var showingDetails = false
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            VStack(alignment: .leading, spacing: 8) {
                // Image Banner
                ZStack {
                    if let image = uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(ProgressView())
                            .onAppear {
                                loadImage()
                            }
                    }
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(10)
                
                // Product Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(product.brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Skin Types
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(product.skinType, id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Description
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Benefits
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(product.benefits.prefix(3), id: \.self) { benefit in
                            Text(benefit)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.1))
                                .foregroundColor(.black)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    Text("عرض")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundColor(.black)
                        .background(Color.lightblue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                        )
                        .cornerRadius(6)
                }
            }
            .padding()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            ProductDetailView(product: product)
        }
    }
    
    // MARK: - Lazy Load Image
    private func loadImage() {
        guard let urlString = product.imageURL, let url = URL(string: urlString), uiImage == nil else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        uiImage = image
                    }
                }
            } catch {
            }
        }
    }
}

// MARK: - Product Detail View
struct ProductDetailView: View {
    @Environment(\.dismiss) var dismiss
    let product: Product
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let urlString = product.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Rectangle().fill(Color(UIColor.secondarySystemBackground))
                                    ProgressView()
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                ZStack {
                                    Rectangle().fill(Color(UIColor.secondarySystemBackground))
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                }
                            @unknown default:
                                Color(UIColor.secondarySystemBackground)
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(product.brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("التصنيف").font(.headline)
                        Text(product.category)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundColor(.black)
                            .background(Color.lightblue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("مناسب لنوع البشرة").font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(product.skinType, id: \.self) { type in
                                Text(type)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .foregroundColor(.black)
                                    .foregroundColor(.black)
                                    .background(Color.lightblue)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                    )
                                
                                RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                    
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("X") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout (unchanged)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    ProductCatalogView()
        .environmentObject(AppState())
}

