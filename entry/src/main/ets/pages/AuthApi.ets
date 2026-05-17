import { http } from '@kit.NetworkKit';

const BASE_URL: string = 'http://121.36.14.143:10001';
// const BASE_URL: string = 'http://192.168.1.100:8088';

export interface BaseResult {
  code?: number;
  msg?: string;
}

export interface LoginResult extends BaseResult {
  token?: string;
}

export interface RegisterResult extends BaseResult {
}

export interface UserInfoResult extends BaseResult {
  carVin?: string;
  carId?: string;
  user?: UserInfo;
}

export interface UserInfo {
  userId?: string;
  nickName?: string;
  userName?: string;
  phonenumber?: string;
  sex?: string;
  avatar?: string;
  birthDate?: string;
}

export interface BindCarResult extends BaseResult {
}

export interface VehicleInfoResult extends BaseResult {
  data?: VehicleDetail;
}

export interface VehicleDetail {
  id?: string;
  userId?: string;
  nickName?: string;
  carName?: string;
  brand?: string;
  carPic?: string;
  carVin?: string;
  horsePower?: string;
  maxPower?: string;
  maxTorque?: string;
  carSize?: string;
  nfc?: string;
  wheelBase?: string;
  frontWheelBase?: string;
  backWheelBase?: string;
  batteryPower?: string;
  enduranceMileage?: string;
  kmh?: string;
  batteryCode?: string;
  batteryType?: string | null;
  batteryCapacity?: string;
  nominalVoltage?: string;
  ratedCurrent?: string;
  workingTemperature?: string;
  delFlag?: string;
  totalTripNum?: string;
  totalTripMile?: string;
  createYm?: string;
  updateTime?: string | null;
}

export interface VehicleStateResult extends BaseResult {
  data?: VehicleState;
}

export interface VehicleState {
  carId?: string;
  door?: string;
  light?: string;
  temperature?: string;
  windLevel?: string;
  circulate?: string;
  setTemp?: string;
  acBtn?: string;
  clearFog?: string;
  fanState?: string;
  playMode?: string;
  processMp3?: string;
  mp3Playing?: string;
  processMp4?: string;
  mp4Playing?: string;
}

export interface FeedbackListResult extends BaseResult {
  data?: FeedbackItem[];
}

export interface FeedbackDetailResult extends BaseResult {
  data?: FeedbackItem;
}

export interface FeedbackItem {
  id?: string;
  userId?: string;
  userName?: string;
  nickName?: string;
  phonenumber?: string;
  content?: string;
  status?: string;
  picUrl?: string;
  delFlag?: string;
  replyRead?: string;
  reply?: string;
  createBy?: string;
  createTime?: string;
  updateBy?: string;
  updateTime?: string;
  remark?: string | null;
}

export interface ControlLogListResult extends BaseResult {
  total?: number;
  rows?: ControlLogItem[];
}

export interface ControlLogItem {
  id?: string;
  userId?: string;
  userName?: string;
  carId?: string;
  carName?: string;
  operaType?: string;
  operaContent?: string;
  createTime?: string;
  updateTime?: string | null;
}

interface LoginParams {
  username: string;
  password: string;
}

export interface RegisterParams {
  nickName: string;
  userName: string;
  phonenumber: string;
  sex: string;
  avatar: string;
  password: string;
  roleIds: string[];
  birthDate: string;
  state: string;
}

interface BindCarParams {
  carVin: string;
}

export interface UpdateVehicleStateParams {
  auto: string;
  door: string;
  light: string;
  temperature: string;
  windLevel: string;
  circulate: string;
  setTemp: string;
  acBtn: string;
  clearFog: string;
  fanState: string;
  playMode: string;
  processMp3: string;
  mp3Playing: string;
  processMp4: string;
  mp4Playing: string;
  carVin: string;
}

interface DoorControlParams {
  carId: string;
  door: string;
}

interface LightControlParams {
  carId: string;
  light: string;
}

export interface AddFeedbackParams {
  userId: string;
  userName: string;
  nickName: string;
  phonenumber: string;
  content: string;
  status: string;
  picUrl: string;
  delFlag: string;
  searchValue: string;
  createBy: string;
  createTime: string;
  updateBy: string;
  updateTime: string;
  remark: string;
}

interface RequestHeader {
  'Content-Type': string;
  Authorization?: string;
}

export class AuthApi {
  static login(username: string, password: string): Promise<LoginResult> {
    const params: LoginParams = {
      username,
      password
    };
    return post<LoginResult>('/app/login', params);
  }

  static register(params: RegisterParams): Promise<RegisterResult> {
    return post<RegisterResult>('/system/user/register', params);
  }

  static getUserInfo(token: string): Promise<UserInfoResult> {
    return get<UserInfoResult>('/getInfo', token);
  }

  static bindCarVin(token: string, carVin: string): Promise<BindCarResult> {
    const params: BindCarParams = {
      carVin
    };
    return post<BindCarResult>('/cockpit/info/bindCarVin', params, token);
  }

  static getVehicleInfo(token: string, carId: string): Promise<VehicleInfoResult> {
    return get<VehicleInfoResult>(`/cockpit/info/${carId}`, token);
  }

  static getVehicleState(token: string, carVin: string): Promise<VehicleStateResult> {
    return get<VehicleStateResult>(`/cockpit/state/${carVin}`, token);
  }

  static updateVehicleState(token: string, params: UpdateVehicleStateParams): Promise<BaseResult> {
    return put<BaseResult>('/cockpit/state', params, token);
  }

  static controlDoor(token: string, carId: string, door: string): Promise<BaseResult> {
    const params: DoorControlParams = {
      carId,
      door
    };
    return post<BaseResult>('/cockpit/control/door', params, token);
  }

  static controlLight(token: string, carId: string, light: string): Promise<BaseResult> {
    const params: LightControlParams = {
      carId,
      light
    };
    return post<BaseResult>('/cockpit/control/light', params, token);
  }

  static controlStop(token: string, carId: string): Promise<BaseResult> {
    return postNoBody<BaseResult>(`/cockpit/control/stop/${carId}`, token);
  }

  static controlRight(token: string, carId: string): Promise<BaseResult> {
    return postNoBody<BaseResult>(`/cockpit/control/right/${carId}`, token);
  }

  static controlLeft(token: string, carId: string): Promise<BaseResult> {
    return postNoBody<BaseResult>(`/cockpit/control/left/${carId}`, token);
  }

  static controlMove(token: string, carId: string): Promise<BaseResult> {
    return postNoBody<BaseResult>(`/cockpit/control/move/${carId}`, token);
  }

  static controlBack(token: string, carId: string): Promise<BaseResult> {
    return postNoBody<BaseResult>(`/cockpit/control/back/${carId}`, token);
  }

  static getFeedbackList(token: string): Promise<FeedbackListResult> {
    return get<FeedbackListResult>('/cockpit/feedback/backList', token);
  }

  static addFeedback(token: string, params: AddFeedbackParams): Promise<BaseResult> {
    return post<BaseResult>('/cockpit/feedback/add', params, token);
  }

  static getFeedbackDetail(token: string, id: string): Promise<FeedbackDetailResult> {
    return get<FeedbackDetailResult>(`/cockpit/feedback/${id}`, token);
  }

  static deleteFeedback(token: string, ids: string): Promise<BaseResult> {
    return deleteData<BaseResult>(`/cockpit/feedback/${ids}`, token);
  }

  static getControlLogList(token: string, pageNum: number = 1, pageSize: number = 10,
    operaContent: string = ''): Promise<ControlLogListResult> {
    const keyword = encodeURIComponent(operaContent);
    return get<ControlLogListResult>(`/cockpit/log/list?pageNum=${pageNum}&pageSize=${pageSize}&operaContent=${keyword}`, token);
  }

  static deleteControlLog(token: string, ids: string): Promise<BaseResult> {
    return deleteData<BaseResult>(`/cockpit/log/${ids}`, token);
  }
}

function get<T>(path: string, token: string): Promise<T> {
  return requestData<T>(path, http.RequestMethod.GET, token);
}

function post<T>(path: string, body: Object, token?: string): Promise<T> {
  return requestData<T>(path, http.RequestMethod.POST, token, body);
}

function postNoBody<T>(path: string, token?: string): Promise<T> {
  return requestData<T>(path, http.RequestMethod.POST, token);
}

function put<T>(path: string, body: Object, token?: string): Promise<T> {
  return requestData<T>(path, http.RequestMethod.PUT, token, body);
}

function deleteData<T>(path: string, token: string): Promise<T> {
  return requestData<T>(path, http.RequestMethod.DELETE, token);
}

function requestData<T>(path: string, method: http.RequestMethod, token?: string, body?: Object): Promise<T> {
  return new Promise((resolve, reject) => {
    const request = http.createHttp();
    const header: RequestHeader = {
      'Content-Type': 'application/json'
    };

    if (token) {
      header.Authorization = token.startsWith('Bearer ') ? token : `Bearer ${token}`;
    }

    const options: http.HttpRequestOptions = {
      method,
      header
    };

    if (body) {
      options.extraData = body;
    }

    request.request(`${BASE_URL}${path}`, options, (err, data) => {
      request.destroy();

      if (err) {
        reject(new Error('网络请求失败，请检查网络连接'));
        return;
      }

      const statusCode: number = data.responseCode;
      if (statusCode < 200 || statusCode >= 300) {
        reject(new Error(`服务器响应异常：${statusCode}`));
        return;
      }

      try {
        const responseText = data.result ? data.result.toString() : '';
        if (responseText.length === 0) {
          const emptyResult = JSON.parse('{}') as T;
          resolve(emptyResult);
          return;
        }

        const result = JSON.parse(responseText) as T;
        resolve(result);
      } catch (parseError) {
        reject(new Error('接口返回数据格式异常'));
      }
    });
  });
}
