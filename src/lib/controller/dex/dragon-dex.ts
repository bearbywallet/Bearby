/*
 * Project: ZilPay-wallet
 * Author: Rinat(hiccaru)
 * -----
 * Modified By: the developer formerly known as Rinat(hiccaru) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2022 ZilPay
 */
import type { GasState, Token, TokenValue } from 'types/store';
import type { TransactionsQueue } from 'app/lib/controller/transaction/index';
import type { NetworkControll } from 'app/lib/controller/network';
import type { TokenControll } from 'app/lib/controller/tokens';
import type { ZilliqaControl } from 'app/lib/controller/zilliqa';
import type { GasControler } from 'app/lib/controller/gas';
import type { CurrencyControler } from 'app/lib/controller/currency';
import type { SettingsControler } from 'app/lib/controller/settings';
import type { AccountControler } from 'app/lib/controller/account';
import type { MobileStorage } from 'app/lib/storage/storage';

import BN from 'bn.js';
import Big from 'big.js';

import { DexStorage } from './dex-storage';
import { Transaction } from 'app/lib/controller/transaction/builder';

import { dexStore } from './state';
import { NIL_ADDRESS } from 'app/config';


Big.PE = 99;

const DEX_GASPRICE = '2300';


export enum GasLimits {
  SwapExactZILForTokens = 2637,
  SwapExactTokensForZIL = 3163,
  SwapExactTokensForTokens = 4183,
  IncreaseAllowance = 1000,
  Default = 5000
}

export class ZIlPayDex extends DexStorage {
  public static FEE_DEMON = new BN(10000);
  public store = dexStore;

  private _token: TokenControll;
  private _zilliqa: ZilliqaControl;
  private _netwrok: NetworkControll;
  private _gas: GasControler;
  private _currency: CurrencyControler;
  private _settings: SettingsControler;
  private _account: AccountControler;
  private _transaction: TransactionsQueue;

  constructor(
    token: TokenControll,
    zilliqa: ZilliqaControl,
    netwrok: NetworkControll,
    gas: GasControler,
    currency: CurrencyControler,
    settings: SettingsControler,
    account: AccountControler,
    transaction: TransactionsQueue,
    storage: MobileStorage
  ) {
    super(storage);
    this._token = token;
    this._zilliqa = zilliqa;
    this._netwrok = netwrok;
    this._gas = gas;
    this._currency = currency;
    this._settings = settings;
    this._account = account;
    this._transaction = transaction;
  }

  public get state() {
    return dexStore.get();
  }

  public get netwrok() {
    return this._netwrok.selected;
  }

  public get gas() {
    return this._gas.store.get;
  }

  public get tokens() {
    return this._token.store.get();
  }

  public get localRate() {
    const settings = this._settings.store.get();
    const currency = this._currency.store.get();

    return settings.rate[currency];
  }

  public get account() {
    const { selectedAddress, identities } = this._account.store.get();
    return identities[selectedAddress];
  }

  public get contract() {
    return this.state.contract[this.netwrok];
  }


  public async swap(pair: TokenValue[]) {
    const [exactToken, limitToken] = pair;
    const limit = this._valueToBigInt(limitToken.value, limitToken.meta);
    const exact = this._valueToBigInt(exactToken.value, exactToken.meta);
    const { header } = await this._zilliqa.getLatestTxBlock();
    const blocknumber = Number(header.BlockNum);
    const deadlineBlock = blocknumber + this.state.blocks;
    const limitAfterSlippage = this.afterSlippage(limit);

    if (exactToken.meta.address[this.netwrok] === NIL_ADDRESS) {
      return this.swapExactZILForTokens(
        exact,
        limitAfterSlippage,
        limitToken.meta.address[this.netwrok],
        deadlineBlock
      );
    } else if (limitToken.meta.address[this.netwrok] === NIL_ADDRESS && exactToken.meta.address[this.netwrok] !== NIL_ADDRESS) {
      return this.swapExactTokensForZIL(
        exact,
        limitAfterSlippage,
        exactToken.meta.address[this.netwrok],
        deadlineBlock
      );
    } else if (limitToken.meta.address[this.netwrok] !== NIL_ADDRESS && exactToken.meta.address[this.netwrok] !== NIL_ADDRESS) {
      return this.swapExactTokensForTokens(
        exact,
        limitAfterSlippage,
        deadlineBlock,
        exactToken.meta.address[this.netwrok],
        limitToken.meta.address[this.netwrok]
      );
    }

    throw new Error('incorrect Pair');
  }


  public async swapExactZILForTokens(exact: BN, limit: BN, token: string, deadlineBlock: number) {
    const params = [
      {
        vname: 'token_address',
        type: 'ByStr20',
        value: token
      },
      {
        vname: 'min_token_amount',
        type: 'Uint128',
        value: String(limit)
      },
      {
        vname: 'deadline_block',
        type: 'BNum',
        value: String(deadlineBlock)
      },
      {
        vname: 'recipient_address',
        type: 'ByStr20',
        value: String(this.account.base16).toLowerCase()
      }
    ];
    const data = JSON.stringify({
      params,
      _tag: 'SwapExactZILForTokens'
    });
    const gas: GasState = {
      gasLimit: String(GasLimits.SwapExactZILForTokens),
      gasPrice: DEX_GASPRICE
    };
    const nonce = await this._transaction.calcNextNonce(this.account);

    return new Transaction(
      String(exact),
      gas,
      this.account,
      this.contract,
      this.netwrok,
      nonce,
      '',
      data
    );
  }

  public async swapExactTokensForZIL(exact: BN, limit: BN, token: string, deadlineBlock: number) {
    const params = [
      {
        vname: 'token_address',
        type: 'ByStr20',
        value: token
      },
      {
        vname: 'token_amount',
        type: 'Uint128',
        value: String(exact)
      },
      {
        vname: 'min_zil_amount',
        type: 'Uint128',
        value: String(limit)
      },
      {
        vname: 'deadline_block',
        type: 'BNum',
        value: String(deadlineBlock)
      },
      {
        vname: 'recipient_address',
        type: 'ByStr20',
        value: String(this.account.base16).toLowerCase()
      }
    ];
    const data = JSON.stringify({
      params,
      _tag: 'SwapExactTokensForZIL'
    });
    const gas: GasState = {
      gasLimit: String(GasLimits.SwapExactTokensForZIL),
      gasPrice: DEX_GASPRICE
    };
    const nonce = await this._transaction.calcNextNonce(this.account);

    return new Transaction(
      String(0),
      gas,
      this.account,
      this.contract,
      this.netwrok,
      nonce,
      '',
      data
    );
  }

  public async swapExactTokensForTokens(exact: BN, limit: BN, deadlineBlock: number, inputToken: string, outputToken: string) {
    const params = [
      {
        vname: 'token0_address',
        type: 'ByStr20',
        value: inputToken
      },
      {
        vname: 'token1_address',
        type: 'ByStr20',
        value: outputToken
      },
      {
        vname: 'token0_amount',
        type: 'Uint128',
        value: String(exact)
      },
      {
        vname: 'min_token1_amount',
        type: 'Uint128',
        value: String(limit)
      },
      {
        vname: 'deadline_block',
        type: 'BNum',
        value: String(deadlineBlock)
      },
      {
        vname: 'recipient_address',
        type: 'ByStr20',
        value: String(this.account.base16).toLowerCase()
      }
    ];
    const data = JSON.stringify({
      params,
      _tag: 'SwapExactTokensForTokens'
    });
    const gas: GasState = {
      gasLimit: String(GasLimits.SwapExactTokensForTokens),
      gasPrice: String(Number(DEX_GASPRICE) - 100)
    };
    const nonce = await this._transaction.calcNextNonce(this.account);

    return new Transaction(
      String(0),
      gas,
      this.account,
      this.contract,
      this.netwrok,
      nonce,
      '',
      data
    );
  }

  public async increaseAllowance(pair: TokenValue[]) {
    const [{ meta }] = pair;
    const balance = this.account.balance[this.netwrok][meta.symbol];
    const params = [
      {
        vname: 'spender',
        type: 'ByStr20',
        value: this.contract
      },
      {
        vname: 'amount',
        type: 'Uint128',
        value: balance
      }
    ];
    const data = JSON.stringify({
      params,
      _tag: 'IncreaseAllowance'
    });
    const gas: GasState = {
      gasLimit: String(GasLimits.IncreaseAllowance),
      gasPrice: DEX_GASPRICE
    };
    const nonce = await this._transaction.calcNextNonce(this.account);

    return new Transaction(
      String(0),
      gas,
      this.account,
      meta.address[this.netwrok],
      this.netwrok,
      nonce,
      '',
      data
    );
  }

  public afterSlippage(amount: BN) {
    if (this.state.slippage <= 0) {
      return amount;
    }

    const _slp = new BN(this.state.slippage * 100);
    const _slippage = ZIlPayDex.FEE_DEMON.sub(_slp);

    return amount.mul(_slippage).div(ZIlPayDex.FEE_DEMON);
  }

  public calcBigSlippage(value: string, slippage: number) {
    if (slippage <= 0 || !value || value === '0') {
      return value;
    }

    const amount = Big(value);
    const demon = Big(String(ZIlPayDex.FEE_DEMON));
    const slip = demon.sub(slippage * 100);

    return amount.mul(slip).div(demon).round(5).toString();
  }

  public getRealAmount(pair: TokenValue[]) {
    const data = {
      amount: Big(0),
      converted: 0,
      gas: GasLimits.Default
    };
    const [exactToken, limitToken] = pair;
    const exactAmount = Big(exactToken.value);
    const bigAmount = exactAmount.mul(this.toDecimails(exactToken.meta.decimals)).round();
    const _amount = new BN(String(bigAmount));
    const localRate = Number(this.localRate) || 0;

    if (exactToken.meta.address[this.netwrok] === NIL_ADDRESS) {
      const pool = limitToken.meta.pool.map((n) => new BN(n));
      const _limitAmount = this._zilToTokens(_amount, pool);
      const bigLimitAmount = Big(String(_limitAmount));

      data.amount = bigLimitAmount.div(this.toDecimails(limitToken.meta.decimals));
      data.converted = localRate * Number(exactToken.value);
      data.gas = GasLimits.SwapExactZILForTokens;

      return data;
    } else if (limitToken.meta.address[this.netwrok] === NIL_ADDRESS && exactToken.meta.address[this.netwrok] !== NIL_ADDRESS) {
      const pool = exactToken.meta.pool.map((n) => new BN(n));
      const _limitAmount = this._tokensToZil(_amount, pool);
      const bigLimitAmount = Big(String(_limitAmount));

      data.amount = bigLimitAmount.div(this.toDecimails(limitToken.meta.decimals));
      data.converted = localRate * Number(data.amount);
      data.gas = GasLimits.SwapExactTokensForZIL;

      if (Big(exactToken.approved).lt(exactAmount)) {
        data.gas += GasLimits.IncreaseAllowance;
      }

      return data;
    } else if (limitToken.meta.address[this.netwrok] !== NIL_ADDRESS && exactToken.meta.address[this.netwrok] !== NIL_ADDRESS) {
      const [ZIL] = this.tokens;
      const inputPool = exactToken.meta.pool.map((n) => new BN(n));
      const outputPool = limitToken.meta.pool.map((n) => new BN(n));
      const [zils, _limitAmount] = this._tokensToTokens(_amount, inputPool, outputPool);
      const bigLimitAmount = Big(String(_limitAmount));
      const zilAmount = Big(String(zils)).div(this.toDecimails(ZIL.decimals));

      data.converted = localRate * Number(zilAmount);
      data.amount = bigLimitAmount.div(this.toDecimails(limitToken.meta.decimals));
      data.gas = GasLimits.SwapExactTokensForTokens;

      if (Big(exactToken.approved).lt(exactAmount)) {
        data.gas += GasLimits.IncreaseAllowance;
      }

      return data;
    }

    return data;
  }

  public getVirtualParams(pair: TokenValue[]) {
    const data = {
      rate: Big(0),
      impact: 0,
      converted: 0
    };

    if (!pair || pair.length < 1) {
      return data;
    }

    const [exactToken, limitToken] = pair;
    const expectAmount = Big(exactToken.value);
    const limitAmount = Big(limitToken.value);
    const localRate = Number(this.localRate) || 0;

    if (exactToken.meta.address[this.netwrok] === NIL_ADDRESS) {
      const zilReserve = Big(limitToken.meta.pool[0]).div(this.toDecimails(exactToken.meta.decimals));
      const tokenReserve = Big(limitToken.meta.pool[1]).div(this.toDecimails(limitToken.meta.decimals));
      const rate = zilReserve.div(tokenReserve);

      data.rate = tokenReserve.div(zilReserve);
      data.impact = this.calcPriceImpact(expectAmount, limitAmount, rate);
      data.converted = localRate;

      return data;
    } else if (limitToken.meta.address[this.netwrok] === NIL_ADDRESS && exactToken.meta.address[this.netwrok] !== NIL_ADDRESS) {
      const zilReserve = Big(exactToken.meta.pool[0]).div(this.toDecimails(limitToken.meta.decimals));
      const tokenReserve = Big(exactToken.meta.pool[1]).div(this.toDecimails(exactToken.meta.decimals));
      const rate = tokenReserve.div(zilReserve);

      data.rate = zilReserve.div(tokenReserve);
      data.impact = this.calcPriceImpact(expectAmount, limitAmount, rate);
      data.converted = localRate * Number(data.rate);

      return data;
    } else if (limitToken.meta.address[this.netwrok] !== NIL_ADDRESS && exactToken.meta.address[this.netwrok] !== NIL_ADDRESS) {
      const [ZIL] = this.tokens;

      const inputZils = Big(exactToken.meta.pool[0]).div(this.toDecimails(ZIL.decimals));
      const inputTokens = Big(exactToken.meta.pool[1]).div(this.toDecimails(exactToken.meta.decimals));
      const outpuZils = Big(limitToken.meta.pool[0]).div(this.toDecimails(ZIL.decimals));
      const outputTokens = Big(limitToken.meta.pool[1]).div(this.toDecimails(limitToken.meta.decimals));

      const inputRate = inputTokens.div(inputZils);
      const outpuRate = outputTokens.div(outpuZils);
      const rate = inputRate.div(outpuRate);

      data.converted = localRate * Number(inputRate);
      data.rate = outpuRate.div(inputRate);
      data.impact = this.calcPriceImpact(expectAmount, limitAmount, rate);

      return data;
    }

    return data;
  }

  public calcPriceImpact(priceInput: Big, priceOutput: Big, currentPrice: Big) {
    try {
      const nextPrice = priceInput.div(priceOutput);
      const priceDiff = nextPrice.sub(currentPrice);
      const value = priceDiff.div(currentPrice);
      const _100 = Big(100);
      const imact = value.mul(_100).round(3).toNumber();
      const percent = Math.abs(imact);

      return percent > 100 ? 100 : percent;
    } catch {
      return 0;
    }
  }

  public toDecimails(decimals: number) {
    return Big(10).pow(decimals);
  }


  private _valueToBigInt(amount: string, token: Token) {
    return new BN(
      Big(amount).mul(this.toDecimails(token.decimals)).round().toString()
    );
  }

  private _zilToTokens(amount: BN, inputPool: BN[]) {
    const [zilReserve, tokenReserve] = inputPool;
    let amountAfterFee = amount;

    if (this.state.protocolFee !== 0) {
      const diff = amount.div(new BN(this.state.protocolFee));
      amountAfterFee = amount.sub(diff);
    }

    return this._outputFor(amountAfterFee, zilReserve, tokenReserve);
  }

  private _tokensToZil(amount: BN, inputPool: BN[]) {
    const [zilReserve, tokenReserve] = inputPool;
    const zils = this._outputFor(amount, tokenReserve, zilReserve);

    if (this.state.protocolFee === 0) {
      return zils;
    }

    const diff = zils.div(new BN(this.state.protocolFee));
    return zils.sub(diff);
  }

  private _tokensToTokens(amount: BN, inputPool: BN[], outputPool: BN[]) {
    const [inputZilReserve, inputTokenReserve] = inputPool;
    const [outputZilReserve, outputTokenReserve] = outputPool;
    const zilIntermediateAmount = this._outputFor(
      amount,
      new BN(inputTokenReserve),
      new BN(inputZilReserve),
      ZIlPayDex.FEE_DEMON
    );
    let zils = zilIntermediateAmount;

    if (this.state.protocolFee !== 0) {
      const diff = zilIntermediateAmount.div(new BN(this.state.protocolFee));
      zils = zilIntermediateAmount.sub(diff);
    }

    return [
      zils,
      this._outputFor(zils, new BN(outputZilReserve), new BN(outputTokenReserve))
    ];
  }

  private _outputFor(exactAmount: BN, inputReserve: BN, outputReserve: BN, fee: BN = new BN(this.state.liquidityFee)) {
    const exactAmountAfterFee = exactAmount.mul(fee);
    const numerator = exactAmountAfterFee.mul(outputReserve);
    const inputReserveAfterFee = inputReserve.mul(ZIlPayDex.FEE_DEMON);
    const denominator = inputReserveAfterFee.add(exactAmountAfterFee);

    return numerator.div(denominator);
  }
}
