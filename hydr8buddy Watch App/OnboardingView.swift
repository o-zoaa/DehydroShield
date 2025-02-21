import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    // Local states to capture user input, all optional until user enters something
    @State private var selectedAge: Int? = nil
    @State private var selectedSex: String? = nil
    @State private var selectedWeight: Double? = nil
    @State private var selectedLocation: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Use a ScrollView so the entire content is visible on watch
                ScrollView {
                    VStack(spacing: 10) {
                        
                        // (1) Welcome text (short, so it won't wrap/truncate)
                        Text("Welcome")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        // (2) Short secondary text
                        Text("Set up your profile")
                            .font(.footnote)
                            .foregroundColor(.white)
                        
                        // (3) Four boxes (clickable), each box shows empty until user picks something
                        
                        // AGE
                        NavigationLink(
                            destination: EditAgeView(age: $selectedAge),
                            label: {
                                OnboardingDataBox(
                                    label: "Age",
                                    // If selectedAge is nil, display empty string
                                    value: selectedAge.map(String.init) ?? "",
                                    boxColor: Color.green.opacity(0.7)
                                )
                            }
                        )
                        
                        // SEX
                        NavigationLink(
                            destination: EditSexView(sex: $selectedSex),
                            label: {
                                OnboardingDataBox(
                                    label: "Sex",
                                    // If selectedSex is nil, display empty string
                                    value: selectedSex ?? "",
                                    boxColor: Color.blue.opacity(0.7)
                                )
                            }
                        )
                        
                        // WEIGHT
                        NavigationLink(
                            destination: EditWeightView(weight: $selectedWeight),
                            label: {
                                OnboardingDataBox(
                                    label: "Weight",
                                    // If selectedWeight is nil, display empty string
                                    value: selectedWeight.map { "\(Int($0)) lbs" } ?? "",
                                    boxColor: Color.orange.opacity(0.7)
                                )
                            }
                        )
                        
                        // LOCATION
                        NavigationLink(
                            destination: EditLocationView(location: $selectedLocation),
                            label: {
                                OnboardingDataBox(
                                    label: "Location",
                                    // If selectedLocation is nil, display empty string
                                    value: selectedLocation ?? "",
                                    boxColor: Color.purple.opacity(0.7)
                                )
                            }
                        )
                        
                        // Some space before the button
                        Spacer(minLength: 10)
                        
                        // (5) Save Profile button
                        Button(action: saveProfile) {
                            Text("Save Profile")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                    } // VStack
                    .padding(.vertical)
                } // ScrollView
            } // ZStack
            .navigationBarHidden(true)
        }
    }
    
    // Save new profile to your ProfileManager
    // If any field is still nil, this guard will prevent saving.
    private func saveProfile() {
        guard
            let age = selectedAge,
            let sex = selectedSex,
            let weight = selectedWeight,
            let location = selectedLocation
        else {
            print("Some fields are still empty; handle partial data or alert user if needed.")
            return
        }
        
        let newProfile = UserProfile(
            age: age,
            weight: weight,
            sex: sex,
            location: location
        )
        profileManager.profile = newProfile
        profileManager.saveProfile()
    }
}

// MARK: - Reusable Box

struct OnboardingDataBox: View {
    let label: String
    let value: String
    let boxColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(boxColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                Spacer()
                // Chevron to indicate tap
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .frame(height: 50)
    }
}

// MARK: - Separate Edit Views

struct EditAgeView: View {
    @Binding var age: Int?
    // Updated ageRange now starts at 9 instead of 1
    private let ageRange = Array(9...100)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Select Age")
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                // Bind the optional Int to the picker
                Picker("Age", selection: Binding(
                    get: { age ?? ageRange.first ?? 9 }, // default if nil
                    set: { age = $0 }
                )) {
                    ForEach(ageRange, id: \.self) { a in
                        Text("\(a)").tag(a)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
        }
    }
}

struct EditSexView: View {
    @Binding var sex: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Select Sex")
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                Picker("Sex", selection: Binding(
                    get: { sex ?? "Male" }, // default if nil
                    set: { sex = $0 }
                )) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                }
                .pickerStyle(WheelPickerStyle())
            }
        }
    }
}

struct EditWeightView: View {
    @Binding var weight: Double?
    private let weightRange = Array(stride(from: 80.0, through: 300.0, by: 1.0))
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Select Weight (lbs)")
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                // Bind the optional Double to the picker
                Picker("Weight", selection: Binding(
                    get: { weight ?? weightRange.first ?? 80 },
                    set: { weight = $0 }
                )) {
                    ForEach(weightRange, id: \.self) { w in
                        Text("\(Int(w)) lbs").tag(w)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
        }
    }
}

struct EditLocationView: View {
    @Binding var location: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Enter Zip Code")
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                // Bind the optional String to the text field
                TextField("Zip Code", text: Binding(
                    get: { location ?? "" },
                    set: { location = $0 }
                ))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(height: 30)
            }
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(ProfileManager())
    }
}
