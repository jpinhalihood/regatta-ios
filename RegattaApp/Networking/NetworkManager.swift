
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = URL(string: "http://localhost:3000/api/")!

    private init() {}

    func sendScore(raceFinish: RaceFinish, completion: @escaping (Result<ScoreResult, Error>) -> Void) {
        guard let url = URL(string: "score", relativeTo: baseURL) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(raceFinish)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let scoreResult = try JSONDecoder().decode(ScoreResult.self, from: data)
                completion(.success(scoreResult))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
}
