//
//  iWebITError.swift
//  MODA
//
//  Created by Admin on 30/07/2023.
//

import Foundation

enum iWebITError: Error {
    case none
    
    case invalidCredentials
    
    case httpError
    
    case decodingError
    
    case loadingContentError
    
    case generalError
}

extension iWebITError: CustomStringConvertible {
    var description: String {
        switch self {
        case .none:
            return ""
        case .invalidCredentials:
            return "Email ou palavra-passe incorretos. Por favor, verifique-os e tente novamente."
        case .httpError:
            return "Sem acesso à internet."
        case .decodingError:
            return "Erro ao processar informação."
        case .loadingContentError:
            return "Erro ao carregar informação."
        case .generalError:
            return "Oops, ocorreu um erro inesperado."
        }
    }
}
