const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe('deploy', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, usdt, nest, 
            cofi,
            pusd,
            peth,
            nestPRCSwap,

            nestCyberInk, nestNFTAuction,
            nestFuturesWithPrice, nestMarket,

            nestGovernance,
            nestOptions, nestFutures,
            nestPriceFacade
        } = await deploy();

		console.log('ok');
		
		return;
		
        let whiteList = [
			'0x2a69bb61416b9eb9582a96eaa63b758c6458a820',
			'0xaf35441f1d852f7d20928c70ca8d387eb416aca4',
			'0x003c10a10ef86ddd67d9151b1b6c1d3aeef8fd6c',
			'0x0cea4b16e26589881ecf767b11a71ddb5cef1f6e',
			'0x548c7b96a9008ecd098206e427ce6efddaed82f9',
			'0x611af993418f12d0fb19b94146cff2998386f73c',
			'0x77775fb62ee4b4179dd5a8599b19e10e0973c424',
			'0xa084755d67532f338025ddb73cb474486cfe1e30',
			'0xc835e3460d69e669d0929adc16438c0080d7dce4',
			'0x0010aa8af7c8de6be3100017335003927ef73852',
			'0x02766e3d25bda6badcd34d7bcea5bf054990444a',
			'0x030618a79711407d15d997eec7c4688a294ad1df',
			'0x03ecd9a40fe68be41c051bf2ba7d9f5da79483c5',
			'0x0414970d160ef1d1d01f3e7f82e39dfcbf10c310',
			'0x04457581df137d62bd90942c30da8e455864aa57',
			'0x04fBAcbA3204eE10aD23C3017af55f42BaE59DE2',
			'0x05c41b80d1a94f267b4818f16b5dbbbc4126d449',
			'0x068c33bd2cc7ccda682da1d5809772283a87040b',
			'0x06c1823607c6A75c53248031E6522eBB04965136',
			'0x07268e226f9ada88fb57b59d816c25bc000da8a0',
			'0x085ca3339d4c953efcc5f6a6d468c7a7742b4fbf',
			'0x090c0048f0a1d8f42614220d93238a2f6da18c70',
			'0x0921c2461638f9aea11c84db149dd8fa29484f20',
			'0x094a96da5a10c521be71df812c52358e01a8c0d7',
			'0x0a56d3afe04608d6c3afdaee624c7cd9113cf8e7',
			'0x0b54ea3896bddf20de4d95260e4549fccd6bb270',
			'0x0bf6b772dad95f49ff46ac60e72cb936775f4c55',
			'0x0c5ceefe0278bc7df7f9a5ab5e91e67135420b77',
			'0x0c93fcc125db795b7746b05373c259d0bdd5f87f',
			'0x0d1088ad8b7f5e81b94582f62ae9de8abac4cf6d',
			'0x0d432c04ec96e4b1ee810e793145a1e90b64cbfc',
			'0x0e59fa2615cabc5b4e50be6dcaa9d6f542b7361c',
			'0x0e985acedeb8511a04c94f971d69e5e4a1ebfab5',
			'0x0feeaf5d0b3b19e93fb72aabd9673c59ea14b545',
			'0x102327d71169e422c9df10b0560aed8dae5a48cd',
			'0x1069497b78c8f29773426ca86dd3acf258bdc563',
			'0x109668E107cCC52BF3B670Bc9AE0cA69875249a5',
			'0x11209662511fdc4a5c496d348f613df97b758126',
			'0x11d1b508b6e7026100f458f8f0eea67554a49088',
			'0x12cf138c7a5b45ed60ae18ff2226c0c391674f3c',
			'0x12f4631e1327aa1efc25f2407239b0488a569013',
			'0x1343375be759d60ee5dc0640464953b18e9acc62',
			'0x137de95dfb70dcc63d111c0b5b117cde17d54f5c',
			'0x138c3f6e14fa928077f67e0d352e2f940cf1184e',
			'0x1390f4DB2d80868a45287100De0dc5d2077eF964',
			'0x1429cecdcf6b85f0f54d6c3a5d136fb54b0ac1a9',
			'0x157f35dcbfbd05073b1d82c8a5eadda3da5088aa',
			'0x15e175391f1a2fb9d2a3350fc89ec35442fc9612',
			'0x1727448afd3fe8c8a59b1e6d6876c82a8ec399a7',
			'0x177252b2ea4c3bca8a42ad634d8610003365635e',
			'0x179dcf07773c5b7899b86ebe425bcef80928a4c1',
			'0x18def71c218664fafb1bba9d0e8b123425cf0dae',
			'0x18e82af79141c01452fac7b2afb9be448c7c5116',
			'0x191b94b4e08ccc1589cf49345bad5f3a4f14a097',
			'0x193a52bc49087025c861b1ded6f9619afdd40ed4',
			'0x19bf4fe746c370e2930cd8c1b3dcfa55270c8ed7',
			'0x1a69a0bc9de639fc51aa0019e449cc458db24d52',
			'0x1a7fcd705383b73edd75d50fb016d1627b44f9dc',
			'0x1babd49c6c5fa0ff9270860626d36bfa33765c6f',
			'0x1c2920c57cc79c7e1b3dc066a7aa8a99de61ab12',
			'0x1cdd03a0103833e83862dcbc08f1fdb891347b57',
			'0x1cfd540baaa092124d8bfb29dbd5762bd80f1b56',
			'0x1eedca0b3370521a90a1c78ffec64a155be1ecba',
			'0x1f466d077cbf6e1e9ddf4078a999e5033be788a3',
			'0x20457d8986004e2f92045990e4e63dcfb670fceb',
			'0x21932184d77c444ebcf2869e287f5c358ce07483',
			'0x21dbddf86dc128698be0dd1a8a9ac07b8a979e27',
			'0x2200430feb24544d67b56e556ed3c41c0d83df6e',
			'0x22084e042dd17328e9bba8d1212a8d8f338f3218',
			'0x2233de6edd2343651c1b6ca7e8161992714c3732',
			'0x2308e51f9406526e3a30fdc7db968c422c560e78',
			'0x2321f0ca0c8e999454e1579a8ffd7e23f15b2168',
			'0x232db37afa304f1f4214ff3c520ca9194764872b',
			'0x2352d16ccc875f9906102cb8f883f8bfd283fce9',
			'0x23cfbb7dd341132bffe77ff128c2427422995aac',
			'0x242534928b405e35826b22b53f9893d6b819ba27',
			'0x25d51f5acae7b31c943d278eac8e8c99e221b1ee',
			'0x25feb1fc9858d09aae1e5c9b6c5bbe7d3a44cdcf',
			'0x26995aa5e8c643236f696226337869f7caf1e5b1',
			'0x26fc1e921c0049ea3b87c689bde166f12f075e82',
			'0x2711e52e71de70545f30889c6a2c0a4e29f32224',
			'0x27a52abad783f56f2de4f0403c08f85b66a66667',
			'0x28fd98443ab2e8cbfb0cf7729a8d6ce28fd74b72',
			'0x292788a70a8e885ff6b0d9a95a4c75366a82930a',
			'0x2988898307260eb238f02798cdf783156219c5cd',
			'0x2a059be9c1c6a4c3931237192b6e718b7a430f22',
			'0x2b43b3fcc798bb824b927e26f75f4caa4cb3ba57',
			'0x2b5af6f41f6bd7efabb4aa6dd8af579efa17f090',
			'0x2bcd827b5767b4aff932b7172b92cdd21b10b43a',
			'0x2c9e70dfeb48aa32b9ad7da92e79db921819dfc5',
			'0x2d9e89a333f78e3502132975d053de062c5c121b',
			'0x2ebb155ad90a73b2ca58354d00aac49f57804b07',
			'0x2eeddeae5a7d88806f26793bb8f7b6d841672649',
			'0x2f229943878d6febc40d26cf782413770d3b6588',
			'0x2fb47dcfd3c8339e2ecd06376f0dae58c4d22116',
			'0x3019233f21f284170884af7ebde616dd6a030bb1',
			'0x301e1b2fa84524271c19a305fccbc5745ea20092',
			'0x30ad3eed4d4003acdeea11aaadc96a88a4048749',
			'0x31261e33b52a6d7067a44a2017f38d775eab1406',
			'0x3144e6e5d2b9bdae5e6a38a9f6a181c9c86c8a38',
			'0x31b3b9882e9295b881857fb17fa1fe0ca2217668',
			'0x33739040e8e769c3d271d525c27fad1d2b7481bb',
			'0x33e358ffdeab16e0b06ac1893f6a6f0a6a85536a',
			'0x3506fbe85e19bf025b228ec58f143ba342c3c608',
			'0x3519bf1eaaeb4c3f5ed80f6d642142ce70c6fd10',
			'0x36435a6f990004be8c6dbd720efe6f480d61ce6d',
			'0x36b624180e8b8b10a120d9f543b134d7b312e371',
			'0x37f1d7e9c55c8d82c94e336e5bd147050a9439a6',
			'0x3807510654bee3d406de996ca500af70f93dfa49',
			'0x385e7c248f4f9fa1e8a5a1f51c4e3465cf3fae79',
			'0x38cee69b5eb9d18f0be140a7d758277b211c0483',
			'0x38dc4f2399534aeee8e1c4aa94fcb088d770a445',
			'0x38e543cd4584819331acd3ff4b34917d341975f2',
			'0x3a21d17317f4f82e6e1732e474b131324b61dc63',
			'0x3b48866656569e65474bc00d6987528f3f3c3d97',
			'0x3b5cd462782adcda670a573da0219b1ad8a66162',
			'0x3b68e4cdf1fd7421b49f759444733861a8b47acb',
			'0x3b70e558ea944e35902b112381cadf5bd7a0244c',
			'0x3c958a55fb5225f139f2bede156fa3acaa33e26f',
			'0x3cec2d6e77f1c9c43c124f25ac79665b719debc7',
			'0x3df2cea47991f57f8eb4b7f1dbecd8257170e348',
			'0x3f6548cff1e13cb99fb1360b6f135acb5d329a07',
			'0x4008a5ebb63dfd7a1410418e0a29ce0cb7550ac2',
			'0x40cbb2ade9cbe21e3216fc816611af8ee5803059',
			'0x41a5b533df057e141736a2f8701c9976b55fad6d',
			'0x41a5e080deb5c2ba2b7a68756f302bbf44642120',
			'0x4268f90188f267849f7fe9feea8785ceab3f12dc',
			'0x43581739f3afa25c29e733be3b78688475ca7d94',
			'0x43916c99cf9b99b219ef171435ab8aed50ed5133',
			'0x4474fe58316c51d055cea351e64b07e3afac6319',
			'0x447a9eebc31c0390a84ac5e4166b8dbeeaeded55',
			'0x449ea9041e5125c53d0606fa4b4128477782fcdb',
			'0x45f791a0653101b530dad7c37d371fd5dbdb1e22',
			'0x465c63680f2a0b4277d9b4cecc3f3310e531a77f',
			'0x46c999ff2d37049e3bbd7bcc2eda13bad9eb6910',
			'0x481a74d43ae3A7BdE38B7fE36E46CF9a6cbb4F39',
			'0x487d58049183b7d1f76710c757620756005bae64',
			'0x491169d9533a042fa262e0e115740d015c67d786',
			'0x498512925bf700bcebf19a190c990cf1e3867f56',
			'0x49a55112cd77d885181c71bed0f62651adcacedd',
			'0x49c807ebcd27570a28259ee5ac43abf23450e40f',
			'0x4a046f54d7385BADFEf6ffebE04e66dA730a833b',
			'0x4b34a56daecf00d77f394070b9ecc6919f6325a7',
			'0x4BbA7715fD58180eD3D43b5f192671e7a9c68502',
			'0x4c07665850d9c389255705dee1c8117bf7a6e938',
			'0x4cd26cfcbd803cfeed79e9deea08605edf7a6ead',
			'0x4cdfbf16742cb99f51f3a30dabce1fd2cb5d1158',
			'0x4d41cc17e4d7aad8b87756e4af1e0b54bf4ea46f',
			'0x4d5543b0f188975fcfb2b4d0d651e68fa11d6809',
			'0x4d5d7e62517b01ef7f6f320760a11974611ce49f',
			'0x4d90cd83c0aac70628607a3b808ac452a06c155c',
			'0x4dcca2a356c51000576a1669cd43a64e1bc3e06b',
			'0x4e1394925edf663f85d2a2effeb25676f3e56214',
			'0x4e764fbdef68d0e4b877c5740cb2ff48bd2b9468',
			'0x4ef0b30f3cf876afc579aa6880cd6503d11b34fa',
			'0x4fe4f5d3ea9a44672179f7db74cd2c28849e63b7',
			'0x5107d84d7bcf14d8bfa6911df22d2141d02ebe9c',
			'0x510da1f73de670ea854e4bd956735420c2b3fbb9',
			'0x515546b26b790a3ebec60316af8b76676b525528',
			'0x51770be898811b4df895ea265c7810d3b9b7605a',
			'0x51ab174b890287006cfa64c619bcefc5fdc2cf14',
			'0x51ac49ebfe773ad9c338d7821bdd23ca1105e7d8',
			'0x51ac6883d9b27bef624b534061a5f21f0380f41b',
			'0x51b15cc1bbfed8432966ece05d0f04324a0b8cad',
			'0x5250d6bf11ae54887f420a2151259f8e4a03cb40',
			'0x526037f075edd78eeaaf957d4d1c8bf4ea5ee7f7',
			'0x52923072d06c20454e1554eb76d82fee7493abeb',
			'0x529658d27b5eb4f8db716c8f49d333a004ca73b6',
			'0x52A721567C679a0CaEd91C52d1b4079D482Fac53',
			'0x52f195263dbaf00dbed24a59a61629f50eddabaf',
			'0x540ed980941991f7c27eab1be0f93e678fe61724',
			'0x556e3ba4c25f9af93ee0940f4a926c890a0f2ddb',
			'0x55a04b595d19eaa43e7bdc83689519dbf6ad3aac',
			'0x55eac74f73524962c3c1dc28e62e162d04d3e48c',
			'0x56897fc85db3fde157a1ea8f9d3aae99913343eb',
			'0x574451d19ea79623080c0a7a42d48c98194c8ea5',
			'0x5842902fadd6f48c47f4acd3ee83161764cd220c',
			'0x58454cad3f07df3b947753932a3b068cc0550bf6',
			'0x58b3170bf952ad1f4ded22a5e5f851b16246980d',
			'0x59036a5fc1f49d6b7b42a145883b1b3093026dea',
			'0x5977ef3c856506beb54a8587fc3ecbb82d127e91',
			'0x59bef2f2b5f9712b8daf1eec3bf477bbdc4b28ee',
			'0x5ae95bcb82a55563faad56b3ca22bf6d13e8b4f9',
			'0x5c921c8ff1fbc8ae744457e28b099f7e8edea211',
			'0x5ca851259e817185c9fa6fea97bb6846ebf3b1d1',
			'0x5cbc7b73e676db1f6d6cc8946d5974c9c2580e6c',
			'0x5d419012e99c22f695017ebe94cfb8d2e2062662',
			'0x5e8e9b6a796e46a314cf3b37d50b9196508052fb',
			'0x5ec334687e91884bb5faeb435e593ed0e9410969',
			'0x5f2530f53018f449ec6696593116a43710e67389',
			'0x5f2aaf7bf35d75da1f8bde5aa71b33dd66b13a14',
			'0x5f8cec07e3a4026f43cdd3661befd7cbe91531a3',
			'0x60069D037b0bfD98c730c06Caa98542D1d49D851',
			'0x607ed25a02088a0c49ad2dca6b2183239678e03e',
			'0x61a050c71a7f6d2730753b72eede61764c75863d',
			'0x62116bd0381db4841d04dc1311d555cb58ce660d',
			'0x623fec547b2e9210e8c7878a392f9eb02a6cdaa8',
			'0x627e25992ec080bc4e5da35bfb39c375827f05a5',
			'0x63d9c97d72f44d4fcca0f1941094b04239812f5b',
			'0x63f9517fcd7e15fe3769e178ad40f3e5cb50ad50',
			'0x641440656E25E5eEBb4aAA5D5D3139210f086858',
			'0x6501032d0215f64082bbdb30a84ce8c1fe654d38',
			'0x653fa667da85a0da995b5bbc05fad49ddbb0eeb5',
			'0x68737ef406dad09763d562f0a992c585f40c84ec',
			'0x6889efd2f4259481343238bc72bc71636d53bb74',
			'0x68af7f1bcdacb582c365c36edd3becabc1f731d0',
			'0x68c533cccd7b0dbd83fd3203a6a97f81ca9d4e2a',
			'0x696018ffe3db63f5271b72a0f473c560616da2df',
			'0x69828318b4762f52a815524b5012f296733e387d',
			'0x6a4fd5f59133aba33040385a4602266117d786cc',
			'0x6b65ff8e42c9dc2adf31722a059a1eb69e9f1a46',
			'0x6c0e00d4b4e1bcdc542a910e106c2c463cc13b8d',
			'0x6d5901f30733e08b70cca2fb8197b28e3eccaf85',
			'0x6f2840f328456ad0cb95e4b64aa8ec9782b02096',
			'0x709ca4c139fdf5030186db506805f7ce981adeff',
			'0x710b8ff55ab8922538b1e30917cef172682ff0d9',
			'0x716a3de975f66511a4dd8251ac2e7c165ae34df1',
			'0x71772f4252b803fce311e22763c8aacc85858b0c',
			'0x7195ddc4ec3ae5c71466c29b454cea29a5807dfe',
			'0x71b9bf20e90648ae0e3b05618e5324433331d8c0',
			'0x72442e9dd7774e61662275183b41b085bf4930bf',
			'0x7246ce7c33e6971a632f4f22a676e1d1ec1b81f9',
			'0x72840d146f391f6e905c15680e12327962e9c3a1',
			'0x728dc12405a1ca03415e0fbe141a5c01deafff68',
			'0x735d653b1f5bc455e183f78eb05bea4b26f29d6c',
			'0x7370a3ba7e80d1552db49c0e9ae39b5ca5af177f',
			'0x73a03eb2c3257ba20a3caba3a68d1fb1b20a4c40',
			'0x73db9ff24fe0b1f4a7f23a919da8c607448eef02',
			'0x747288ae0ad2f1501045be8bbc6dee68698a9ddd',
			'0x74e9d92e0171ab22b78cf9c2f20a47d355ffa826',
			'0x7541472ceae6256b11af49354992283b83bc792c',
			'0x77e4d45edeedd4b7f356dfaf1672dfa76f4a0314',
			'0x78631cbd0cf80f90fd059fdf5af0e2f0d14fb302',
			'0x7896d89b85299092aec04ea65d12435865ec370f',
			'0x78dbA641814Cc43a2803a4CCEf4f0aCC369Bb9eF',
			'0x79e46bae90b42b94e9e91e8855e15e8210e7ad48',
			'0x7a4f724db738afddaaa2bcbe90a57c4398792c90',
			'0x7a6e8a56c7f0cbad1999b9251213e5918b05efb3',
			'0x7b31eeae3e035926bf11091aaf1fc319a2eb4402',
			'0x7c06023845a982a06608535505fb052884d8080c',
			'0x7cd1caffb300ba59a40743cec1746784e7a7024a',
			'0x7df9df3f78f4ca9fdecc5de12a0aa19353eba54a',
			'0x7e64471cd9675e122427752d101cc959f15c415e',
			'0x7eb31084fc830767af8493516305139046bc221c',
			'0x806e65ba98419e938c395689ccdc2864e94afa7f',
			'0x8085ff2ac81ad8fa05ce5b83817154af5f9db279',
			'0x80b6a85168cdb8f0128a90790396b4cb9a3c7075',
			'0x82c44b4ae34065820299afc615dfc965438615ab',
			'0x871e642fB0047DC6CE7E79297f07C3ee02D81fC0',
			'0x873b3e839ac2bb6829fd5c1176ca9f5f023a7313',
			'0x878968036a0744B1517571D772EED517415Eb4Ca',
			'0x88d2cc1c9fc5ca05bb7c1a82837995676e4f8155',
			'0x899cf26ed5d7f71d487ac708085b8336fefe8b10',
			'0x89ee11df917d590617165b7dfa3ef4ac4f0fe281',
			'0x8a6ec7bbe0d8e6eb2719f4e222e2f3ad10ebab0d',
			'0x8ae1e9ebab06aa3676cace8f727b69d6853212bc',
			'0x8c00718b54dab8c49becfed84b65156b39c99af7',
			'0x8c2d3a761e801d0ec63384fbbbd40816f48c0969',
			'0x8c6341a430c64afb1191f32c45516f89cd7aff95',
			'0x8e4237fd48bbb843683c93bacad6a6966c9e9883',
			'0x8e53219f38ede100b94dbaf04c568f25008cfa23',
			'0x8fc2b1fd265ff6d138b7eddc4afe4e5ce714e589',
			'0x903dcad7a831a04f5203fbf6438c901a80c18a85',
			'0x9048db4c4ff3f0cfa3936b9e33cae17a2e66e9a8',
			'0x906ad31cada7f16c5e072a3a1ab785308c2ed6d4',
			'0x929ba44469ceea8745a9938e403b633324b0958b',
			'0x93b98272d87e82e35118b23ecbfb9e5c45261aa2',
			'0x950e91cc2c97af779b08daa099245678ecb3535b',
			'0x951caa47f4b9af27a7ed5ef933e9e21affc58a74',
			'0x953c13d733e7d46793738a5767434966acfc4e60',
			'0x95656d549fe00e0e40580fe7fa3d3c4c75400224',
			'0x95783e91d2045ef6504c7d3913c98934a84439b8',
			'0x95ef8c327cab4a1a7cb893b7ab9f1dc8c0530ff0',
			'0x9672b5e11a5adba2243d5a0df6bf58bef1397870',
			'0x972225c541febecf6896d827dfe039830e9ec296',
			'0x973c0712bd91da2bdce1dda29cff6c272c972686',
			'0x975f9291bd85f9a4e43954a54d31fd6c0ec7114d',
			'0x976c96c826adf8ef3eeb9403857252bad6a9aeb7',
			'0x97dc3dee0e4a7b466c5dd6cc6dbe8fcf2e9ec77e',
			'0x9844201d684bbfaba3e082785afec9324e8537f8',
			'0x9877ed2d9afa790b31bfabec736b25fb8c552352',
			'0x996c84489c7bfe9c02fe94036980aadb34fba1b2',
			'0x9976f037cc520693a46e3928b0858faabe613087',
			'0x99db557ccc31c0b72820a24dc520aa4400a1eaf6',
			'0x9a3041a2bcbc94d394752d60b3533d8acb7e0f09',
			'0x9c3d007766e801568fa3f7e251dc76bbdd477733',
			'0x9c8fa30125464ed830520d49097814c4de090ee4',
			'0x9cc9852eca03837072e5585f804638ea09e1e91b',
			'0x9d03e41baa44c87ceb504457620ebad3e5d117f2',
			'0x9dcbc332c1c7ed345e282be863c88fa1615f7922',
			'0x9e3ab6801cfaca1df0ec8016c1be1082e8d18ba5',
			'0x9e81505be8ae8e53ceb07041c79dd8a7ee50a540',
			'0x9f14e1c7f42fa4c2fcf3f34cdfab8f6c893eb340',
			'0x9fdca8cecb72db1f6e4d88f27cb31bb14c81e9c1',
			'0xa056d660d21ff59a52e2d9adf1eefaffaa875814',
			'0xa09195e828021ab11486aafda46e28b71d28cb49',
			'0xa093afdb1b845a68e06d1434c1466eaf0d53ea22',
			'0xa1709bd42b258174c9e2715dcb21a92c7c46f097',
			'0xa1ded1ff6b4b54a73eac7c8d97958e3fa6a0a969',
			'0xa26d9c7ba5a7eec46de93bf3e78805cb7e0dc5ff',
			'0xa310257bf16954569483cb52c4b802c6bc4d6167',
			'0xa3289ecdd38482bc2da18180543c82c1d26104a0',
			'0xa33fc17645307ce41917a8da23e38d2d1f2557b8',
			'0xa34ddcfa391d2d1c3f7bbbdf23902880a80c80a0',
			'0xa4c03fab02872d6ba66552178ea8e3a11d58471a',
			'0xa62e276e7767f1393cd2aa682eea3b4c47dce86a',
			'0xa63b833c4bb36bf5e9d1c981fb17a4ff37dd68f3',
			'0xa64a8bdd1be43a4eefb3c4826ed87261870cb932',
			'0xa73a01eb447aa512b6cdf0b1b3aa2f4eb3dab97a',
			'0xa7b474d7a00a26202e62ea510e72e6b1e4663a56',
			'0xa7c83dcf18c093eb7bd832c945ce263a1ba3e358',
			'0xa81a2534b9527c12c63410ef230b543cba718297',
			'0xa8661a8156de692e2a7aaf9e5268c90f2e6fcb48',
			'0xa8b7d97570c34068efac4ec51deddd4c16602ae8',
			'0xa8e00fa5954c8ed2f9e05d64f74e6d35fbcb7e79',
			'0xa984c454d98af0b5ed8e5b18807323e1b881bb1a',
			'0xa9b208a221d3950ada12a12f821dfd52b758e155',
			'0xaa4c60e0292645640f4f0e6b8333ce292084cf8d',
			'0xaAcb96F0aBe180d6FCe1A60Fe2e579Db351899cE',
			'0xab2ddb856575a7f982d469679d4c275bc8473b88',
			'0xAC1281Db6B2D853F01FD1fe85cD6d6dC4096Ca7B',
			'0xAca316C975e5bA0F909CbE4dee4dE3c049cAc933',
			'0xad548543f7ca61b61179e7d9e78613900e10a74b',
			'0xae191b50bf9d5f2792f03a7b7d519c1ca0c19fb6',
			'0xae1d27a6cb5b569ce8124c78370cf5a5d7400b70',
			'0xae82eb087d2f65e96a0ed636b2af0988845a2114',
			'0xb05782d42dee64171e8bd71faf197892477fe3a0',
			'0xb0604d2370a815f0951b487ee33a16522216f514',
			'0xb07ec1067a0aa2e17a608fe54a7b00d2ee147c4e',
			'0xb140d70d3d833855cd59f169ac944e9c29b98712',
			'0xb314ee7a98ea7e5b44e4e8082135024a52fc79ec',
			'0xb354737b8c119b6f7318caaa631723c2f4b1ef33',
			'0xb533c548d50ed51e77d2511dd90e581f0c1782bf',
			'0xb5392a36e0df46846e1029fbd7f84f9ed7c6ea0f',
			'0xb60d9f27e1498d6e85648242169267d7d9cf3454',
			'0xb7156dd3763a433ef133844c27de83ed5bffe3dd',
			'0xb7937b9f4812904792bb149487a8aa50b42c8cf5',
			'0xb7db189f31e77a7272f1308488346cbe202e0d11',
			'0xb7db2aa0982e1a1db8659d5c0dc37d94bf612b8b',
			'0xb7e9e23e71f13873276f96413c3b53bdca7736f0',
			'0xb836d8b434a3028b5ebb9f0778f6e07a24cb9e0f',
			'0xb87997cddd4843d0bfef3f9739ded0bc4e698121',
			'0xb8a5d12de3bf01526098f23c0f60e7aa73dcb8c5',
			'0xb91ad841865fb210cc5f89137005de626d56defb',
			'0xb95ca17aba62caf6bff672fcef1b04a1e7f906e4',
			'0xb9adbfab19d54ee49080df6fd2d4a129e858ac6a',
			'0xb9dc5f5b15500bb0dff235911a3a7435c8240b6d',
			'0xba36866cdb81a5794a32183ec6b995db3698c6a4',
			'0xbab8b4d0635e904c5cfb3236144a0d671585ea9d',
			'0xbb1404f7c2062ba5a1487ee425ed80b79819970d',
			'0xbc6f1d461253eef838632cc7c07c6ef9b5980b71',
			'0xbd9040b74230d2761b35e594e9d2213b01985766',
			'0xbdd18a22046107b631d1a065be0f034bc13c52f4',
			'0xbde7dd55cdc2ab6f175a3dbdc997380967a75ff0',
			'0xbe176e7bc6066fb9542b4cda26b0d98e0226419f',
			'0xbf5a7f849023d4058e15e4d92b7d6ad78a8aa0fe',
			'0xbf7cc9c957bf5fd611b007f642af7f02f95a4add',
			'0xc15c951cd5371c41e9530371ca161a605817236e',
			'0xc1ed4f2f8afa9570e192fb4c94868a828dcf4824',
			'0xc34182a1bd8cb969f8a3130b328b837553e575d8',
			'0xc38b84cfaec98208d663b003845e9f7aee38e864',
			'0xc44c66794db90821b9c35272c0bc3e7d62b79fa6',
			'0xc4eca93f259156d98ff765add39611a193b068e2',
			'0xc5117adda92f95ac9562522d861fd35a01404e59',
			'0xc55cbb84abc6c7d9731757415120840faa5e424e',
			'0xc5f3f7913660804470cefcc60b1516955c0a7796',
			'0xc6619c0fa689c2f64865f1ca6f292550ff6a41eb',
			'0xc672609f023060dceac2d1f96790ef89228e523f',
			'0xc6da99639d66f687b4aae430f1d33c2009a286c0',
			'0xc71c90ff53f47fb5a8f0851da702d172c7c4b335',
			'0xc78734ceffd958b5dc0d5cbab862dd9427a489d0',
			'0xc7a6cde6bcb118e9d160bec47d02e2896875d8c0',
			'0xc82eb94954b3ca399b136910a24eff8edfe8ae9e',
			'0xc849c1f5c275f774dfc4925cf55823d8fadb93b7',
			'0xc8c39e3406b857674381f6ebcded210a8037e205',
			'0xc8e996ad7bcfa802aeaef3b8c17adcdcb4e43158',
			'0xc8ed43d9c84140a04cbb3ed3373c58d170f5c834',
			'0xc968b208068706962530ddb392f502b439eaf02a',
			'0xc9848f01353977ea69afcbb1101de9e04596a81a',
			'0xc9d12445efb8cc95ff8f826a89d78f84b9487686',
			'0xcacdde84c6d5713c73f85a090838f8792d9e44b1',
			'0xcadad2b2aad2289931dbac429b09ad84978dd99d',
			'0xcb55337c458df51c3d6b1b809ffacfe05c63d16f',
			'0xcc355dabb5191ad60a80548ddb2a7116fa5ce887',
			'0xccce685a3a7215cf9becda440ca3b6a5d2858724',
			'0xcd605c4ea264da635dac89bb0e19f811645cab66',
			'0xcdaf2b63e1361edcbe3d52043f5b1f57c43ff345',
			'0xce06a6dffd89be7ad7a2b96641d300561393a252',
			'0xce8b57ab463692af834786202f36d449cb644a17',
			'0xcec3b03fac147fbff921447d7319a19f7684c4e8',
			'0xd07c2579a777ab27aa401b5a6adbaa18266533d3',
			'0xD104329FEA41BEFCF50F97465CD0138073a042Dc',
			'0xd118398194c3a0cef2a10e385fed11789250144f',
			'0xd11d74306e28369d0347ce096600ceb1395bdda7',
			'0xd2fb7a4eada851c969cc67b7e0a526e739935ddb',
			'0xd3627d110edd64a4c2510521199de183edd58566',
			'0xd368a427e41ec7d60296ee1834b8ec752772eee4',
			'0xd512213ca7f167e2889a29629653f867096c8a53',
			'0xd5ccbbcd44f2a445ddbf4c1266dcd52788705e9a',
			'0xd64e57ad8ba30db1d9a7bd5c5bd0a7f095eb788f',
			'0xd670c6874347b5c905903985799ad03963b72de8',
			'0xd6965d550dcdf7ae05f7dfcd5997ba9ab6f21fbe',
			'0xd6dc3772cc7a339fbf22a6ef8530adc37edd9032',
			'0xd70f330967f6d7df455a635b1af5d0aae36f694f',
			'0xd74207a71a8cbc089508e4ed8778231234cc66c3',
			'0xd96de6d7aedd4dae2b9366e4e801b030f149031d',
			'0xda95366fe96fbfb131cbf252e3fa7af573c4bed5',
			'0xdaf040c853043773f516d5a33ea7e3ad0d97740b',
			'0xdb5be3c65eaa0ca2e36c74e492773863c5d08f5f',
			'0xdba5e3a227ac0156f1cedb53922951243325685a',
			'0xdced828e70decb3b612bde1031d253408df848c6',
			'0xde28390fd2f40252fd4dc3869315684b9b0d3f9f',
			'0xDEdc4B125B324E9c1fd29c4ff808cac9D6Ca3c37',
			'0xe08db5b5a09352a89e21340d5b55c7c8cf588ede',
			'0xe1365c6c116e07ca85a19adbdf260591b5eb3e5b',
			'0xe1b301138c2aeabd70841261ff297a0aeb4863d8',
			'0xe1d1663892a1dfe82c2cd11810c9188b8a9b505f',
			'0xe1e4e65ed77b4ce334c3aef9d4f76898a48701b7',
			'0xe2a2669ae5819bbfa2bd4022a7dcc9f16ba3086d',
			'0xe471103f9ce36fe629f06c244cabf257590b2e93',
			'0xe4bbefa3cf60e2b37c90f2ecd72d1ed936218966',
			'0xe56a36ea63d8bc590682085d2ce187cfaf5a9281',
			'0xe6116430a3fee86d4b8cc366c13a959075538dae',
			'0xe791e48536cd0b7a02b4b6c9ce60174d9ad09597',
			'0xe7ab9927e9757ffb2be88af4aee56791ced586c7',
			'0xe7b28cc28614fdd07f3b9597a59807ae5fc74c38',
			'0xe7c9b084a2a487c97b9efe5ea4321bd3d9128537',
			'0xe7fc60cec962aceb5d2805ca119bfe91476bce9d',
			'0xe811124db1725bcf8ddb45a300ec8bec9317a4d5',
			'0xe82654e9dfc6c29b69b536b1bf53f5bbca82deb1',
			'0xe83120006d095f311a7546c86be2879c7a604350',
			'0xe92920d2184bef155a8b6bb3d1ab9915a69ac2ab',
			'0xeaa7d229c794c9b9126c77915e69c85864b1e993',
			'0xeaf5ebc71aca834613133416e168c9fb0449f1fe',
			'0xeb41acb7cca431cf7622fe242478e2cab38e061b',
			'0xec022fbdc042a7a3968b4d18d4b0763ba667a570',
			'0xec229a34cf25e87121f3c3bbd0a40887305ad94a',
			'0xec39c8c564fc625c7db669f52dab5a040ef2ab6e',
			'0xec4000557d466478f5ff10a2c8a36ac3c3d5f294',
			'0xec9e93ed7fa50a3424a61737d2fa7c2c79e2ae20',
			'0xed4d8d2a5bf5c8e1fac4a647b364027a182a75c9',
			'0xee23bfc7dff09e038be61f823dcd701b786a59b4',
			'0xee730e159c93ad3c56933ec2dac0e30ac28c92dc',
			'0xef0180077ca1f2d62fc420d7473dffb1adfd8138',
			'0xefdd3bb43ecae908ea81dd9b1852e8759310c6ef',
			'0xF0148dBE2F22deD13B157fe2CB877560ACcD1c8b',
			'0xf04aba2c7f1ed9aba89bbd5d5b49304201059197',
			'0xf0ac0e8eb76764a1d9015ce20788e8ac6b2b13b3',
			'0xf21bd23ed6ce90660ba53746f50091505496796c',
			'0xf2920beaa254660dda9887e62e5435086dcd79e0',
			'0xf456141b8fbdbe7b5417e9f5e3adc1c11cac8481',
			'0xf55342f4f149806512f8a2ae353ee845e2a2e41f',
			'0xf5cc82f62e09c9c963badea669a6c4f6a6caecdc',
			'0xf61f4971ec5ab94d62f2e9e600d17daf512f0c06',
			'0xf65110a541ac6bbdb2d13581314b6774fbc46978',
			'0xf661051a1593d345d4772ab68fa135dc529eaae8',
			'0xf75fe22fbda09ad1490a2520fc71fe176faee68f',
			'0xf8948d879830211017d5b3156dcd7b0f8a339a10',
			'0xf8f50338cb207305b1810ea7ec2693e3a60cdccf',
			'0xf9c335e0b3eceb06d8d05f678acb7aca23919307',
			'0xfa9c1c4b51f21a965d51f25fd82cf193a0f361ba',
			'0xfb8000799413855938f464aece2e16d0bc0e9e69',
			'0xfbc52490635543945e488a035f4f61bccae52341',
			'0xfc52b8616b951833ac63edd084abe9c9e9f26cf8',
			'0xfce7c56832f3da3a5d357e105f19e8a3efe56f13',
			'0xfd43cb5856f9651607b387a2118b07ed5119e93e',
			'0xfd58bd235aecbbfe28f2950c3e86168205bd7493',
			'0xfe2482eddaaf851bd98c15ce0dbbc097f34c48bf',
			'0xfe52554a3c63659eab9b83f8cc86f2ec212103ef',
			'0xff017d9cd92b57af4cd3d801739f72fe519cbbda',
			'0xff6b9a7cb1ffd16d09e020fa72f5cda79dc5651c',				
        ];

        for (var i = 0; i < whiteList.length; ++i) {
            for (var j = i + 1; j < whiteList.length; ++j) {
                if (BigInt(whiteList[i]) == BigInt(whiteList[j])) {
                    console.log('i = %d, j = %d', i, j);
                }
            }
        }

        const nodes = whiteList.map(addr=>keccak256(addr));
        const merkleTree = new MerkleTree(nodes, keccak256, { sortPairs: true });

        //console.log(merkleTree.toString());
        //await nestMarket.whiteListBuy(2562821, merkleTree.getHexProof(nodes[2]));
        await nestMarket.setMerkleRoot(merkleTree.getRoot(), { nonce: 70 });
		return;
		
        // 概率        抽奖nft起始编号（16进制）                          首发nft起始编号（16进制）
        // ------------------------------------------------------------------------------------
        // 1%          16777216（0x1000000）                           16807216（0x1007530）
        // 5%          83886080（0x5000000）                           83926080（0x5009c40）
        // 10%        167772160（0xa000000）                          167822160（0xa00c350）
        // await nestCyberInk.release(nestMarket.address, 0x1007530, 1, 16);
        // await nestCyberInk.release(nestMarket.address, 0x5009c40, 1, 16);
        // await nestCyberInk.release(nestMarket.address, 0xa00c350, 1, 16);
    });
});
