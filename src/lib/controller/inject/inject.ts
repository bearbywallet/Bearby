/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import RNFS from 'react-native-fs';

import { Device } from 'app/utils';

export class InjectScript {
	public entryScrip: string | null = null;

	constructor() {
		this.init();
	}

	// Cache inpage.js so that it is immediately available
	private async init() {
		this.entryScrip = Device.isIos()
			? await RNFS.readFile(`${RNFS.MainBundlePath}/inpage.js`, 'utf8')
			: await RNFS.readFileAssets(`inpage.js`);

		return this.entryScrip;
	}
}
