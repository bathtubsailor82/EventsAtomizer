//
//  XMLDownloader.swift
//  EventsAtomizer
//
//  Created by localadmin on 19/02/2025.
//


import Foundation


struct XMLDownloader {
    enum DownloadError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case authenticationRequired
        case invalidData
    }
    
    struct DownloadParameters {
        let startDate: Date
        let numberOfWeeks: Int
        let includeCanceledVenues: Bool
        let displayIdService: Bool
    }
    
    static func buildURL(parameters: DownloadParameters) -> URL? {
        let baseURL = "https://ssrsprd2019web.coe.int/WS_ReportServer/Pages/ReportViewer.aspx"
        let dateString = formatDate(parameters.startDate)
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "%2fEVENTS%2fAllDatacards", value: nil),
            URLQueryItem(name: "rs:Command", value: "Render"),
            URLQueryItem(name: "rs:Format", value: "XML"),
            URLQueryItem(name: "StartDateParameter", value: dateString),
            URLQueryItem(name: "NumberOfWeeks", value: String(parameters.numberOfWeeks)),
            URLQueryItem(name: "CanceledVenuesParameter", value: String(parameters.includeCanceledVenues)),
            URLQueryItem(name: "DisplayIdService", value: String(parameters.displayIdService))
        ]
        
        return components?.url
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}


extension XMLDownloader {
    static func downloadXML(parameters: DownloadParameters) async throws -> Data {
            guard let url = buildURL(parameters: parameters) else {
                throw DownloadError.invalidURL
            }
            
            // Configuration de URLSession pour gérer les certificats SSL
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 300
            
            // Ajout des headers nécessaires
            configuration.httpAdditionalHeaders = [
                "Accept": "application/xml",
                "User-Agent": "EventsAtomizer/1.0"
            ]
            
            let session = URLSession(configuration: configuration)
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw DownloadError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    return data
                case 401, 403:
                    throw DownloadError.authenticationRequired
                default:
                    throw DownloadError.invalidResponse
                }
            } catch let error as URLError {
                // Gestion spécifique des erreurs réseau
                switch error.code {
                case .notConnectedToInternet:
                    throw DownloadError.networkError(NSError(domain: "XMLDownloader",
                                                           code: 1,
                                                           userInfo: [NSLocalizedDescriptionKey: "Not connected to internet"]))
                case .timedOut:
                    throw DownloadError.networkError(NSError(domain: "XMLDownloader",
                                                           code: 2,
                                                           userInfo: [NSLocalizedDescriptionKey: "Request timed out"]))
                case .cannotFindHost:
                    throw DownloadError.networkError(NSError(domain: "XMLDownloader",
                                                           code: 3,
                                                           userInfo: [NSLocalizedDescriptionKey: "Cannot find host. Please check your connection and try again."]))
                default:
                    throw DownloadError.networkError(error)
                }
            } catch {
                throw DownloadError.networkError(error)
            }
        }
}
