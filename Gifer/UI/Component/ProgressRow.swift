import SwiftUI

struct ProgressRow: View {
    @State var id: String
    @State var progress: CGFloat
    @State var width: CGFloat = 300
    @State private var complete: Bool?
    
    private let gap = CGFloat(5)
    private let textSize = CGFloat(100)
    private let percentSize = CGFloat(40)
    private let checkSize = CGFloat(10)
    private var barSize: CGFloat { width-textSize-checkSize-percentSize-4*gap }
    private var percent: Int { Int(progress<0 ? 0 : (progress>1 ? 1 : progress)*100) }
    
    var body: some View {
        HStack(spacing: gap) {
            Text(id)
                .frame(width: textSize, alignment: .leading)
                .lineLimit(1)
            RoundedRectangle(cornerRadius: 7)
                .frame(width: barSize, height: 7)
                .foregroundColor(.section)
                .overlay {
                    HStack {
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .trailing)
                            .frame(width: (progress>1 ? 1 : progress) * barSize)
                            .foregroundColor(.green)
                        Spacer(minLength: 0)
                    }
                    .cornerRadius(7)
                }
            Text("\(percent)%")
                .frame(width: percentSize)
            Circle()
                .frame(width: checkSize, height: checkSize)
                .foregroundColor(complete == nil ? .transparent : (complete! ? .green : .red ))
                .overlay {
                    Image(systemName: complete == nil ? "" : (complete! ? "checkmark" : "multiply"))
                        .foregroundColor(.white)
                        .font(.system(size: checkSize*0.7, weight: .medium))
                }
        }
        .padding(.horizontal, gap)
        .onChange(of: progress) { handleProgressChange($0) }
        .onAppear { handleProgressChange(progress) }
    }
}

extension ProgressRow {
    func handleProgressChange(_ progress: CGFloat) {
        if progress < 0 {
            complete = false
            return
        }
        
        if progress > 1 {
            complete = true
        }
    }
}

struct ProgressRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProgressRow(id: "Failed Case", progress: -1)
            ProgressRow(id: "Progressing", progress: 0.33)
            ProgressRow(id: "Fully Done But Not Complete", progress: 1)
            ProgressRow(id: "Complete", progress: 2)
        }
    }
}
