import SwiftUI

enum SpecialRepresentation: String, CaseIterable {
    case overflow = "OFL"
    case underflow = "UFL"
    case negativeOverflow = "-OFL"
    case negativeUnderflow = "-UFL"
    case infinity = "∞"
    case negativeInfinity = "-∞"
    case notANumber = "--"

    static func isSpecialRepresentation(_ value: String) -> Bool {
        return SpecialRepresentation.allCases.contains { $0.rawValue == value }
    }
}

struct UnitInputView<UnitType>: View where UnitType: RawRepresentable & Hashable & CaseIterable, UnitType.RawValue == String, UnitType: UnitWithPowerOfTen {
    @Binding var value: Double
    @State var unit: UnitType
    @State private var displayedValue: String = ""
    @State private var lastRenderedUnit: UnitType?
    @State private var lastRenderedValue: String = ""
    let label: String
    let description: String
    var showNegationDecorator: Bool = false
    var precision: Int = 4
    @FocusState private var isFocused: Bool
    
    private var unitCases: [UnitType] {
        Array(UnitType.allCases)
    }
    
    private func convertFromEngineeringNotation() -> Double {
        var d = Decimal(string: displayedValue) ?? Decimal(0)
        var x = unit.powerOfTen
        while (x != 0) {
            if (x > 0) {
                d *= 10;
                x -= 1
            } else {
                d /= 10
                x += 1
            }
        }
        return NSDecimalNumber(decimal: d).doubleValue
    }
    
    private func displaySpecialRepresentation(_ representation: SpecialRepresentation) {
        displayedValue = representation.rawValue
    }
    
    private func convertToEngineeringNotation(value: Double) {
        // Determine the appropriate unit and value in engineering notation
        let targetUnit = determineAppropriateUnit(for: value)
        let engineeringValue = value / pow(10, Double(targetUnit.powerOfTen))
        unit = targetUnit
        
        if value.isInfinite {
            if (value < 0) {
                displaySpecialRepresentation(.negativeInfinity)
            } else {
                displaySpecialRepresentation(.infinity)
            }
        } else if value.isNaN {
            displaySpecialRepresentation(.notANumber)
        } else {
            if (engineeringValue == 0) {
                displayedValue = "0"
            } else if (abs(engineeringValue) < 0.001) {
                displaySpecialRepresentation(engineeringValue < 0 ? .negativeUnderflow : .underflow)
            } else if (abs(engineeringValue) > 9999) {
                displaySpecialRepresentation(engineeringValue < 0 ? .negativeOverflow : .overflow)
            } else {
                if (abs(engineeringValue) >= 1) {
                    let candidate = String(format: "%.\(precision)g", engineeringValue)
                    if (abs(Double(candidate)!) >= 1000) {
                        // Rounded up to a higher unit
                        if (targetUnit.isGreatest) {
                            if (abs(Double(candidate)!) < 10000) {
                                displayedValue = candidate
                            } else {
                                displaySpecialRepresentation(engineeringValue < 0 ? .negativeOverflow : .overflow)
                            }
                        } else {
                            // Try again
                            convertToEngineeringNotation(value: Double(candidate)!*pow(10, Double(targetUnit.powerOfTen)))
                        }
                    } else {
                        displayedValue = candidate
                    }
                } else {
                    var trimmedValue = String(format: "%.\(precision)f", engineeringValue)
                    while trimmedValue.last == "0" {
                        trimmedValue = String(trimmedValue.dropLast())
                    }
                    if (trimmedValue.last == ".") {
                        trimmedValue = String(trimmedValue.dropLast())
                    }
                    displayedValue = trimmedValue
                }
            }
        }
        lastRenderedValue = displayedValue
        lastRenderedUnit = unit
    }
    
    private func determineAppropriateUnit(for value: Double) -> UnitType {
        // Assuming that the units are sorted in the order of their magnitude
        let sortedUnits = unitCases.sorted { $0.powerOfTen < $1.powerOfTen }
        
        for unit in sortedUnits {
            if (value.isInfinite || value == 0 || value.isNaN) {
                if unit.powerOfTen == 0 {
                    return unit;
                }
            } else {
                let unitValue = abs(value) / pow(10, Double(unit.powerOfTen))
                if unitValue >= 1 && unitValue < 1000 {
                    return unit
                }
            }
        }
        
        // Return the original unit if no suitable unit is found
        return unit
    }
    
    private func toggleNegation() {
        if !displayedValue.hasPrefix("-") {
            displayedValue = "-" + displayedValue
        }
        else {
            displayedValue = displayedValue.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        }
    }
    
    private func disabled() -> Bool {
        value.isNaN
    }
    
    private func dirty() -> Bool {
        lastRenderedValue != displayedValue || (lastRenderedUnit != nil && lastRenderedUnit != unit)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: -5) {
            HStack(alignment: .center) {
                Spacer()
                HStack {
                    Text(label)
                        .foregroundColor(.baseLabelTextColor)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.baseLabelTextColor)
                }
                .padding(.horizontal, 8)
                .background(Color.baseComponentBackgroundColor) // Background for both Text views
                Spacer()
            }
            .zIndex(1)
            ZStack {
                Color.baseDarkRed.adjusted(brightness: 0.9).edgesIgnoringSafeArea(.all)
                HStack {
                    VStack {
                        Spacer(minLength: 12)
                        TextField("", text: $displayedValue)
                            .multilineTextAlignment(.trailing)
                            .font(.custom("Segment7Standard", size: 30))
                            .kerning(3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(Color.basePrimaryOrange.adjusted(brightness: disabled() ? 0.5 : 1.6))
                            .blur(radius: 4)
                            .disabled(true)
                            .overlay(
                                ZStack {
                                    TextField("", text: $displayedValue)
                                        .multilineTextAlignment(.trailing)
                                        .font(.custom("Segment7Standard", size: 30))
                                        .kerning(3)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color.basePrimaryOrange.adjusted(brightness: disabled() ? 0.5 : 1.5))
                                        .tint(Color.basePrimaryOrange.adjusted(brightness: 1.5))
                                        .disabled(disabled())
                                        .onTapGesture {
                                            if SpecialRepresentation.isSpecialRepresentation(displayedValue) {
                                                displayedValue = ""
                                            }
                                        }
                                        .keyboardType(.decimalPad)
                                        .focused($isFocused)
                                        .onAppear {
                                            convertToEngineeringNotation(value:value)
                                        }
                                        .onChange(of: value) { newValue in
                                            convertToEngineeringNotation(value:value)
                                        }
                                        .onChange(of: isFocused) { focused in
                                            if !focused {
                                                if dirty() {
                                                    value = convertFromEngineeringNotation()
                                                    convertToEngineeringNotation(value:value)
                                                }
                                            }
                                        }
                                        .onDisappear {
                                            if dirty() {
                                                self.value = convertFromEngineeringNotation()
                                            }
                                        }
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                if isFocused {
                                                    if showNegationDecorator {
                                                        Spacer()
                                                        Button(action: toggleNegation) {
                                                            Text("-")
                                                                .font(.custom("Segment7Standard", size: 30))
                                                                .foregroundColor(.black)
                                                        }
                                                        .frame(minWidth: 44)
                                                    }
                                                    Spacer()
                                                    ForEach(unitCases, id: \.self) { unitCase in
                                                        Button(action: {
                                                            selectUnit(unitCase)
                                                        }) {
                                                            Text(unitCase.shouldRender ? unitCase.rawValue : unitCases.count == 1 ? "⏎" : "_")
                                                                .foregroundColor(Color.baseSecondaryRed.adjusted(brightness: 1.5))
                                                                .fontWeight(unitCase == unit ? .bold : .regular)
                                                        }
                                                        .frame(minWidth: 44)
                                                        Spacer()
                                                    }
                                                }
                                            }
                                        }
                                }
                            )
                        Spacer()
                    }
                    Text(unit.shouldRender && !disabled() ? unit.rawValue : "")
                        .foregroundColor(Color.baseSecondaryRed.adjusted(brightness: 1.5))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 34)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .overlay(ZStack {
                            Text(unit.shouldRender && !disabled() ? unit.rawValue : "")
                                .foregroundColor(Color.baseSecondaryRed.adjusted(brightness: 1.7))
                                .blur(radius: 4)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 34)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        })
                    Spacer()
                }
            }
            .frame(height: 40)
            .cornerRadius(5)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.baseLabelTextColor, lineWidth: 5)
                        .padding(-8)
                        .offset(y: -1)
                        .mask(RoundedRectangle(cornerRadius: 4)
                            .padding(-7)
                            .padding([.top], -5)
                            .offset(y: -1))
                }
            )
            .padding([.top], 5)
            
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    }
    
    private func selectUnit(_ unitCase: UnitType) {
        unit = unitCase
        dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
