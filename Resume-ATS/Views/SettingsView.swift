import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: Int = 2  // 0: Light, 1: Dark, 2: System
    @AppStorage("autoSave") private var autoSave = true

    var body: some View {
        ZStack {
            Color(red: 24 / 255, green: 24 / 255, blue: 38 / 255).edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 20) {
                Text("Réglages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top)

                // Apparence Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.accentColor)
                        Text("Apparence")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Thème")
                                    .foregroundColor(.white)
                                Text("Mode clair ou sombre")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Menu {
                                Button("Clair", action: { colorScheme = 0 })
                                Button("Sombre", action: { colorScheme = 1 })
                                Button("Système", action: { colorScheme = 2 })
                            } label: {
                                HStack {
                                    Text(
                                        colorScheme == 0
                                            ? "Clair" : (colorScheme == 1 ? "Sombre" : "Système"))
                                    Image(systemName: "gear")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 44 / 255, green: 44 / 255, blue: 60 / 255))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Préférences Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.accentColor)
                        Text("Préférences")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Sauvegarde automatique")
                                    .foregroundColor(.white)
                                Text("Sauvegarder automatiquement les modifications")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: $autoSave)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color(red: 44 / 255, green: 44 / 255, blue: 60 / 255))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
