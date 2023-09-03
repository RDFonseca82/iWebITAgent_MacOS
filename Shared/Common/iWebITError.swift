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
    
    case incompleteOperation
}

extension iWebITError: CustomStringConvertible {
    var description: String {
        switch self {
        case .none:
            return ""
        case .invalidCredentials:
            return "O IdSync inserido não existe. Por favor, verifique-o e tente novamente."
        case .httpError:
            return "Sem acesso à internet."
        case .decodingError:
            return "Erro ao processar informação."
        case .loadingContentError:
            return "Erro ao carregar informação."
        case .generalError:
            return "Oops, ocorreu um erro inesperado."
        case .incompleteOperation:
            return "Não foi possível concluir a operação."
        }
    }
}
