import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

struct CatFactsResponse: ApiModel, Decodable {
    typealias Model = CatFactsResponse
    
    var all: [CatFact]
}

struct CatFact: Decodable {
    var text: String
}

struct CryptoResponse: ApiModel, Decodable {
    typealias Model = CryptoResponse
    
    var ticker: CryptoTicker
    var timestamp: Int
}

struct CryptoTicker: Decodable {
    var base: String
    var target: String
    var price: String
}

protocol ApiModel {
    associatedtype Model: Decodable
    
    static func makeModel(from data: Data) -> Model?
}

extension ApiModel {
    static func makeModel(from data: Data) -> Model? {
        var model: Model?
        do {
            model = try JSONDecoder().decode(Model.self, from: data)
        } catch let error {
            print(error.localizedDescription)
        }
        return model
    }
}

class NetworkManager {
    func fetch<Model: ApiModel>(model: Model.Type, fromUrl url: URL, completion: ((Model?) -> Void)? = nil) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let data = data else {
                print("No data")
                return
            }
            
            let returnValue = Model.makeModel(from: data) as? Model
            completion?(returnValue)
            
        }.resume()
    }
}

let network = NetworkManager()
var catsApiURL = URL(string: "https://cat-fact.herokuapp.com/facts")!
var cryptoApiURL = URL(string: "https://api.cryptonator.com/api/ticker/btc-usd")!

var allCatFacts: [CatFact]?
func fetchRandomCatFact() {
    network.fetch(model: CatFactsResponse.self, fromUrl: catsApiURL) { model in
        allCatFacts = model?.all
        if let randomFact = allCatFacts?.randomElement() {
            print(randomFact.text)
        } else {
            print("No new cat facts found :(")
        }
    }
}

func fetchBitcoinPrice() {
    network.fetch(model: CryptoResponse.self, fromUrl: cryptoApiURL) { model in
        guard let model = model,
            let price = Double(model.ticker.price) else {
            return
        }
        
        let ticker = model.ticker
        let formattedTime = Date(timeIntervalSince1970: TimeInterval(model.timestamp))
        let formattedPrice = String(format: "%.2f", price)
        
        print("\(formattedTime): 1 \(ticker.base) == \(formattedPrice) \(ticker.target)")
    }
}

fetchRandomCatFact()
fetchBitcoinPrice()
