import CoinKit
import CurrencyKit
import EthereumKit

class TransactionInfoViewItemFactory {

    private func actionSectionItems(title: String, coinValue: CoinValue, rate: CurrencyValue?, incoming: Bool?) -> [TransactionInfoModule.ViewItem] {
        let currencyValue = rate.flatMap {
            CurrencyValue(currency: $0.currency, value: $0.value * coinValue.value)
        }

        return [
            .actionTitle(title: title, subTitle: coinValue.coin.title),
            .amount(coinAmount: coinValue.formattedString, currencyAmount: currencyValue?.formattedString, incoming: incoming)
        ]
    }
    
    private func feeString(coinValue: CoinValue, currencyValue: CurrencyValue?) -> String {
        var parts = [String]()
        
        if let formattedCoinValue = ValueFormatter.instance.format(coinValue: coinValue) {
            parts.append(formattedCoinValue)
        }
        
        if let currencyValue = currencyValue, let formattedCurrencyValue = ValueFormatter.instance.format(currencyValue: currencyValue) {
            parts.append(formattedCurrencyValue)
        }

        return parts.joined(separator: " | ")
    }
    
    private func priceString(coinValue1: CoinValue, coinValue2: CoinValue) -> String {
        let priceDecimal = coinValue1.value.magnitude / coinValue2.value.magnitude
        let price = ValueFormatter.instance.format(value: priceDecimal, decimalCount: priceDecimal.decimalCount, symbol: nil) ?? ""

        return "\(coinValue2.coin.code) = \(price) \(coinValue1.coin.code)"
    }
    
    private func rateString(currencyValue: CurrencyValue, coinCode: String) -> String {
        let formattedValue = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) ?? ""
        
        return "balance.rate_per_coin".localized(formattedValue, coinCode)
    }

    func items(transaction: TransactionRecord, rates: [Coin: CurrencyValue], lastBlockInfo: LastBlockInfo?) -> [[TransactionInfoModule.ViewItem]] {
        let status = transaction.status(lastBlockHeight: lastBlockInfo?.height)
        var middleSectionItems: [TransactionInfoModule.ViewItem] = [.date(date: transaction.date)]

        switch transaction {
        case let evmIncoming as EvmIncomingTransactionRecord:
            let coinRate = rates[evmIncoming.value.coin]

            middleSectionItems.append(.status(status: status, completed: "transactions.received".localized, pending: "transactions.receiving".localized))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: evmIncoming.value.coin.code)))
            }

            middleSectionItems.append(.from(value: evmIncoming.from))
            middleSectionItems.append(.id(value: evmIncoming.transactionHash))

            return [
                actionSectionItems(title: "transactions.receive".localized, coinValue: evmIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let evmOutgoing as EvmOutgoingTransactionRecord:
            let coinRate = rates[evmOutgoing.value.coin]

            middleSectionItems.append(.status(status: status, completed: "transactions.sent".localized, pending: "transactions.sending".localized))

            if let rate = rates[evmOutgoing.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * evmOutgoing.fee.value)
                middleSectionItems.append(.fee(value: feeString(coinValue: evmOutgoing.fee, currencyValue: feeCurrencyValue)))
            }

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: evmOutgoing.value.coin.code)))
            }

            middleSectionItems.append(.to(value: evmOutgoing.to))
            middleSectionItems.append(.id(value: evmOutgoing.transactionHash))

            return [
                actionSectionItems(title: "transactions.send".localized, coinValue: evmOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        case let swap as SwapTransactionRecord:
            middleSectionItems.append(.status(status: status, completed: "transactions.swapped".localized, pending: "transactions.swapping".localized))

            if let rate = rates[swap.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * swap.fee.value)
                middleSectionItems.append(.fee(value: feeString(coinValue: swap.fee, currencyValue: feeCurrencyValue)))
            }
            if let valueOut = swap.valueOut {
                middleSectionItems.append(.price(price: priceString(coinValue1: swap.valueIn, coinValue2: valueOut)))
            }
            middleSectionItems.append(.id(value: swap.transactionHash))

            var sections = [
                actionSectionItems(title: "tx_info.you_pay".localized, coinValue: swap.valueIn, rate: rates[swap.valueIn.coin], incoming: false)
            ]

            if let valueOut = swap.valueOut {
                sections.append(actionSectionItems(title: "tx_info.you_get".localized, coinValue: valueOut, rate: rates[valueOut.coin], incoming: true))
            }
            sections.append(middleSectionItems)

            return sections

        case let approve as ApproveTransactionRecord:
            let coinRate = rates[approve.value.coin]

            middleSectionItems.append(.status(status: status, completed: "transactions.approve".localized, pending: "transactions.approving".localized))

            if let rate = rates[approve.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * approve.fee.value)
                middleSectionItems.append(.fee(value: feeString(coinValue: approve.fee, currencyValue: feeCurrencyValue)))
            }

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: approve.value.coin.code)))
            }

            middleSectionItems.append(.to(value: approve.spender))
            middleSectionItems.append(.id(value: approve.transactionHash))
            
            let currencyValue = coinRate.flatMap {
                CurrencyValue(currency: $0.currency, value: $0.value * approve.value.value)
            }

            let isMaxValue = approve.value.isMaxValue
            let coinAmount = isMaxValue ? "transactions.value.unlimited".localized : currencyValue?.formattedString ?? ""
            let currencyAmount = isMaxValue ? "∞" : approve.value.formattedString

            return [
                [
                    .actionTitle(title: "transactions.approve".localized, subTitle: approve.value.coin.title),
                    .amount(coinAmount: coinAmount, currencyAmount: currencyAmount, incoming: nil)
                ],
                middleSectionItems
            ]

        case let contractCall as ContractCallTransactionRecord:
            var sections: [[TransactionInfoModule.ViewItem]] = [
                [.actionTitle(title: contractCall.method ?? "transactions.contract_call".localized, subTitle: TransactionInfoAddressMapper.map(contractCall.contractAddress))]
            ]

            if contractCall.outgoingEip20Events.count > 0 {
                var youPaySection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: "tx_info.you_pay".localized, subTitle: nil)
                ]

                for event in contractCall.outgoingEip20Events {
                    let currencyValue = rates[event.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * event.value.value)
                    }
                    youPaySection.append(.amount(coinAmount: event.value.formattedString, currencyAmount: currencyValue?.formattedString, incoming: false))
                }

                sections.append(youPaySection)
            }

            if contractCall.incomingEip20Events.count > 0 || contractCall.incomingInternalETHs.count > 0 {
                var youGetSection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: "tx_info.you_get".localized, subTitle: nil)
                ]

                if let ethCoin = contractCall.incomingInternalETHs.first?.value.coin {
                    var ethValue: Decimal = 0
                    for tx in contractCall.incomingInternalETHs {
                        ethValue += tx.value.value
                    }

                    let currencyValue = rates[ethCoin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * ethValue)
                    }
                    youGetSection.append(.amount(coinAmount: CoinValue(coin: ethCoin, value: ethValue).formattedString, currencyAmount: currencyValue?.formattedString, incoming: true))
                }

                for event in contractCall.incomingEip20Events {
                    let currencyValue = rates[event.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * event.value.value)
                    }
                    youGetSection.append(.amount(coinAmount: event.value.formattedString, currencyAmount: currencyValue?.formattedString, incoming: true))
                }

                sections.append(youGetSection)
            }

            middleSectionItems.append(.status(status: status, completed: "tx_info.status.completed".localized, pending: "tx_info.status.pending".localized))

            if let rate = rates[contractCall.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * contractCall.fee.value)
                middleSectionItems.append(.fee(value: feeString(coinValue: contractCall.fee, currencyValue: feeCurrencyValue)))
            }

            middleSectionItems.append(.id(value: contractCall.transactionHash))

            sections.append(middleSectionItems)

            return sections

        case let btcIncoming as BitcoinIncomingTransactionRecord:
            let coinRate = rates[btcIncoming.value.coin]
            
            middleSectionItems.append(.status(status: status, completed: "transactions.received".localized, pending: "transactions.receiving".localized))
            
            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: btcIncoming.value.coin.code)))
            }
            
            btcIncoming.from.flatMap { middleSectionItems.append(.from(value: $0)) }
            middleSectionItems.append(.id(value: btcIncoming.transactionHash))
            if btcIncoming.showRawTransaction {
                middleSectionItems.append(.rawTransaction)
            }
            btcIncoming.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp).flatMap { middleSectionItems.append(.lockInfo(lockState: $0)) }
            
            return [
                actionSectionItems(title: "transactions.receive".localized, coinValue: btcIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]
            
        case let btcOutgoing as BitcoinOutgoingTransactionRecord:
            let coinRate = rates[btcOutgoing.value.coin]
            
            middleSectionItems.append(.status(status: status, completed: "transactions.sent".localized, pending: "transactions.sending".localized))
            
            if let fee = btcOutgoing.fee, let rate = rates[fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * fee.value)
                middleSectionItems.append(.fee(value: feeString(coinValue: fee, currencyValue: feeCurrencyValue)))
            }
            
            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: btcOutgoing.value.coin.code)))
            }
            
            btcOutgoing.to.flatMap { middleSectionItems.append(.to(value: $0)) }
            middleSectionItems.append(.id(value: btcOutgoing.transactionHash))
            btcOutgoing.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp).flatMap { middleSectionItems.append(.lockInfo(lockState: $0)) }

            return [
                actionSectionItems(title: "transactions.send".localized, coinValue: btcOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        default: return []
        }
    }

}
