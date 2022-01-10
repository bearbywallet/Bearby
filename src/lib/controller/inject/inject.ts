/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import RNFS from 'react-native-fs';

import { inpageStore, inpageStoreUpdate } from './store';
import { Device } from 'app/utils';

export class InjectScript {
	public store = inpageStore;

	public async sync() {
		if (Device.isIos()) {
			const entryScrip = await RNFS.readFile(`${RNFS.MainBundlePath}/inpage.js`, 'utf8');

			inpageStoreUpdate(entryScrip);
			// inpageStoreUpdate(`console.log('injectd');`);
		}

		if (Device.isAndroid()) {
			const entryScrip = await RNFS.readFileAssets(`inpage.js`);

			inpageStoreUpdate(entryScrip);
		}
	}
}
