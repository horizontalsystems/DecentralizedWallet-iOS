import CoinKit

class CoinStorage {
    private let storage: ICoinRecordStorage

    init(storage: ICoinRecordStorage) {
        self.storage = storage
    }

    private func coin(record: CoinRecord_v19) -> Coin? {
        guard let tokenType = TokenType(rawValue: record.tokenType) else {
            return nil
        }

        switch tokenType {
        case .erc20:
            guard let address = record.erc20Address else {
                return nil
            }

            return coin(record: record, coinType: .erc20(address: address))
        case .bep20:
            guard let address = record.erc20Address else {
                return nil
            }

            return coin(record: record, coinType: .bep20(address: address))
        case .bep2:
            guard let symbol = record.bep2Symbol else {
                return nil
            }

            return coin(record: record, coinType: .bep2(symbol: symbol))
        }
    }

    private func coinRecord(coin: Coin, tokenType: TokenType) -> CoinRecord_v19 {
        CoinRecord_v19(
                id: coin.id,
                title: coin.title,
                code: coin.code,
                decimal: coin.decimal,
                tokenType: tokenType.rawValue
        )
    }

    private func coin(record: CoinRecord_v19, coinType: CoinType) -> Coin {
        Coin(
                title: record.title,
                code: record.code,
                decimal: record.decimal,
                type: coinType
        )
    }

}

extension CoinStorage: ICoinStorage {

    var coins: [Coin] {
        storage.coinRecords.compactMap { coin(record: $0) }
    }

    func save(coin: Coin) -> Bool {
        switch coin.type {
        case .erc20(let address):
            let record = coinRecord(coin: coin, tokenType: .erc20)
            record.erc20Address = address
            storage.save(coinRecord: record)
            return true
        case .bep20(let address):
            let record = coinRecord(coin: coin, tokenType: .bep20)
            record.erc20Address = address
            storage.save(coinRecord: record)
            return true
        case .bep2(let symbol):
            let record = coinRecord(coin: coin, tokenType: .bep2)
            record.bep2Symbol = symbol
            storage.save(coinRecord: record)
            return true
        default: ()
        }

        return false
    }

}

extension CoinStorage {

    enum TokenType: String {
        case erc20
        case bep20
        case bep2
    }

}
