//
//  ContentView.swift
//  XPay Swift SDK Demo APP
//
//  Created by Amir Ghafoor on 21/05/2024.
//

import SwiftUI;
import XPayPaymentKit
struct TVShow: Identifiable {
    var id: String { name }
    let name: String
}
struct ContentView: View {
    @State private var isReady = false
    @State private var selectedShow: TVShow?
    @State private var isLoading: Bool = false
    struct APIError: Error {
        let details: [String: Any]
    }
    private func makeNetworkCall(
        payload: [String: Any],
        endPoint: String,
        success: @escaping ([String: Any]) -> Void,
        failure: ((Error) -> Void)? = nil
    ) {
        guard let url = URL(string: "http://localhost:4242/create-payment-intent") else {
            failure?(URLError(.badURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            failure?(error)
            return
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                failure?(error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                failure?(URLError(.badServerResponse))
                return
            }
            if !(200...299).contains(httpResponse.statusCode) {
                if let data = data, let errorDetails = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    failure?(APIError(details: errorDetails))
                } else {
                    failure?(URLError(.badServerResponse))
                }
                return
            }

            guard let data = data,
                  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                  let jsonResponse = jsonObject as? [String: Any] else {
                failure?(URLError(.cannotParseResponse))
                return
            }
            success(jsonResponse)
        }

        task.resume()
    }
    
    let keysConfig = KeysConfiguration(accountId: "your_account_id", publicKey: "your_account_public_api_key", hmacKey: "your_account_hmac_api_key")
    
    let customStyleConfiguration = CustomStyleConfiguration(inputConfiguration: InputConfiguration(cardNumber: InputField(label: "Card Number", placeholder: "Enter card number"), expiry: InputField(label: "Expiry Date", placeholder: "MM/DD"), cvc: InputField(label: "CVC1", placeholder: "cvc")), inputStyle: InputStyle(height: 25, textColor: .black, textSize: 17, borderColor: .gray, borderRadius: 5, borderWidth: 1), inputLabelStyle: InputLabelStyle(fontSize: 17, textColor: .gray), onFocusInputStyle: OnFocusInputStyle(textColor: .black, textSize: 17, borderColor: .blue, borderWidth: 1), invalidStyle: InvalidStyle(borderColor: .red, borderWidth: 1, textColor: .red, textSize: 14), errorMessageStyle: ErrorMessageStyle(textColor: .red, textSize: 14))
    func onBindiscount(data: [String: Any]){
        print("data in  host app : \(data)")
    }
    var handler = XPayController()
    func dd(){
        self.isLoading = true
        let customerEmail = "demo@xstak.com"
        let customerName = "John Doe"
        let customerPhone = "03012354678"
        let shippingAddress1 = "Industrial state"
        let shippingCity = "lahore"
        let shippingCountry = "pakistan"
        let shippingProvince = "punjab"
        let shippingZip = "54000"
        let randomDigits = Int.random(in: 100000...999999)
        let orderReference = "order-\(randomDigits)"

        // Constructing the payload dictionary
        let payload: [String: Any] = [
            "amount": 5,
            "currency": "PKR",
            "payment_method_types": "card",
            "customer": [
                "email": customerEmail,
                "name": customerName,
                "phone": customerPhone
            ],
            "shipping": [
                "address1": shippingAddress1,
                "city": shippingCity,
                "country": shippingCountry,
                "province": shippingProvince,
                "zip": shippingZip
            ],
            "metadata": [
                "order_reference": orderReference
            ]
        ]
        makeNetworkCall(payload: payload, endPoint: "", success: {response in
            let clientSecret =  response["clientSecret"] as? String ??  ""
            handler.confirmPayment(customerName: "Amir", clientSecret:clientSecret, paymentResponse: {data in
                let errorValue = data["error"] as? Bool ?? false
                let message = data["message"] as? String ?? "payment error"
                let paymentStatus = data["status"] as? String ?? "Failed"
                self.isLoading = false
                selectedShow = TVShow(name: "\(message). error : \(errorValue). Payment Status : \(paymentStatus)")
            });
        }, failure:{response in
            self.isLoading = false
            print("create intent api error  : \(response)")
        } )

    }
    
    var body: some View {
        VStack {
            XPayPaymentForm(keysConfiguration: keysConfig, customStyle: customStyleConfiguration, onBinDiscount: {data in
                print("data in  host app : \(data)")
            },onReady: {isReady in
                self.isReady = isReady
            }, controller: handler).padding(.horizontal)
            Button(action: {
                        dd() // Call your function
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.maximum(0, 10))
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(7)
                        } else {
                            Text("Pay PKR 5.00")
                                .frame(maxWidth: .infinity)
                                .padding(.maximum(0, 10))
                                .background(isReady ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(7)
                        }
                    }
                    .disabled(!isReady || isLoading)
                    .padding(.top, 10)
                    .padding(.horizontal)

                        Button(action: {
                            handler.clear()
                        }) {
                            Text("Clear")
                                .frame(maxWidth: .infinity)
                                .padding(.maximum(0, 10))
                                .background(Color.gray )
                                .foregroundColor(.white)
                                .cornerRadius(7)
                        }
                        .disabled(isLoading)
                        .padding(.top, 3)
                        .padding(.horizontal)
        }.alert(item: $selectedShow) { show in
            Alert(title: Text(show.name), dismissButton:.default(Text("Ok")))
        }
    }

}
//
