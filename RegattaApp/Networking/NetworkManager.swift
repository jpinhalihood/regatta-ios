
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = URL(string: "http://localhost:3000/api/")!

    private init() {}

    func sendScoreRequest(regattaId: UUID, boats: [Boat], races: [Race], throwouts: Int, completion: @escaping (Result<[ScoreResult], Error>) -> Void) {
        guard let url = URL(string: "score", relativeTo: baseURL) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let scoringRequest = ScoringRequest(regattaId: regattaId, boats: boats, races: races, throwouts: throwouts)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Or whatever format your backend expects for dates

        do {
            let jsonData = try encoder.encode(scoringRequest)
            request.httpBody = jsonData
        } catch {
            print("Error encoding request: \(error)")
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network request failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Server error, status code: \(statusCode)")
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
                completion(.failure(NetworkError.serverError(statusCode: statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Or whatever format your backend expects for dates

            do {
                let scoreResults = try decoder.decode([ScoreResult].self, from: data)
                completion(.success(scoreResults))
            } catch {
                print("Error decoding response: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw response data: \(jsonString)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL was invalid."
        case .noData:
            return "No data was received from the server."
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)."
        }
    }
}
