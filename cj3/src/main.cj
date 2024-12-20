package cj3
import std.console.*
import std.convert.*
import std.collection.*
import std.sort.*

struct grammer{
    let left:String
    let rights:Array<String>
    init(left:String,rights:Array<String>){
        this.left=left
        this.rights=rights
    }
    
}

struct Trie_node{
    var symbol:String
    var children:ArrayList<Trie_node>
    init(){
        this.symbol=""
        this.children=ArrayList<Trie_node>()
    }
    init(symbol:String){
        this.symbol=symbol
        this.children=ArrayList<Trie_node>()
    }

}

struct Queue<T>{
    private var queue:ArrayList<T>
    public init(){
        queue=ArrayList<T>()
    }
    public init(queue: ArrayList<T>){
        this.queue=queue
    }
    public func size():Int{
        return queue.size
    }
    public func push(item:T){
        queue.append(item)
    }
    public func pop():T{
        return queue.remove(0)
    }
    public func isEmpty():Bool{
        return queue.isEmpty()
    }
    public func front():T{
        return queue[0]
    }
    public func clone():Queue<T>{
        return Queue<T>(queue.clone())
    }
    public func clear(){
        queue.clear()
    }
} 

struct Stack<T>{
    private var stack:ArrayList<T>
    public init(){
        stack=ArrayList<T>()
    }
    public init(stack: ArrayList<T>){
        this.stack=stack
    }
    public func size():Int{
        return stack.size
    }
    public func push(item:T){
        stack.append(item)
    }
    public func pop():T{
        return stack.remove(stack.size-1)
    }
    public func isEmpty():Bool{
        return stack.isEmpty()
    }
    public func top():T{
        return stack[stack.size-1]
    }
}

extend Array<String>{
    public operator func<(other:Array<String>):Bool{
        var s1=""
        var s2=""
        for(i in this){
            s1+=i
        }
        for(i in other){
            s2+=i
        }
        if(s1<s2){
            return true
        }
        return false
    }
}

func gram_sort(gram:grammer):grammer{
    var gram_temp=gram
    func compare(a:String,b:String):Ordering{
        var f1=a.startsWith(gram.left)
        var f2=b.startsWith(gram.left)
        if(f1==f2){
            if(a>b){return Ordering.LT}
            return Ordering.GT
        }
        if(f1){
            return Ordering.LT
        }
        return Ordering.GT
    }
    gram_temp.rights.sortBy(comparator:compare)
    return gram_temp
}

func pre_grammer(string:String):grammer{
    let st=string.replace(" ", "")
    let s=st.split("->")
    let left=s[0]
    let right=s[1]
    let rights=right.split("|")
    var gram=grammer(left,rights)
    gram=gram_sort(gram)
    return gram
}

func compare(a:grammer,b:grammer):Ordering{
    if(a.left<b.left){
        return Ordering.LT
    }
    if(a.left>b.left){
        return Ordering.GT
    }
    if(a.rights<b.rights){
        return Ordering.LT
    }
    return Ordering.GT
}

class Parsing{
    public var grams:ArrayList<grammer>
    public var first=HashMap<String,HashSet<String>>()
    public var follow=HashMap<String,HashSet<String>>()
    public var select=HashMap<String,HashSet<String>>()
    public var matrix=HashMap<String,HashMap<String,grammer>>()
    public init(grams:ArrayList<grammer>){
        this.grams=grams
    }
    var start=""
    
    func pre_grams(){
        if(start.isEmpty()){
            start=grams[0].left
        }
        grams.sortBy(comparator:compare)
        var size=this.grams.size
        var i=1
        while(i<size){
            if(this.grams[i].left==this.grams[i-1].left){
                var rights=ArrayList<String>(this.grams[i-1].rights)
                rights.appendAll(this.grams[i].rights)
                this.grams[i-1]=grammer(this.grams[i-1].left,rights.toArray())
                this.grams.remove(i)
                size--
            }
            i++
        }
    }

    func pre_first_follow_select_matrix(){
        var str_temp=HashSet<String>()
        for(i in this.grams){
            this.first.put(i.left,HashSet<String>())
            this.follow.put(i.left,HashSet<String>())
            for(j in i.rights){
                this.first.put(j,HashSet<String>())
                this.select.put(i.left+"->"+j,HashSet<String>())
                var s=j

                while(!s.isEmpty()){
                    var flag=false
                    for(k in this.grams where s.endsWith(k.left)){
                        s=s.removeSuffix(k.left)
                        flag=true
                    }
                    if(!flag){
                        let s_arr=s.toRuneArray()
                        str_temp.put(s_arr[s_arr.size-1].toString())
                        s=s.removeSuffix(s_arr[s_arr.size-1].toString())
                    }
                }
            }
        }
        str_temp.put("$")
        str_temp.remove("ε")
        for(i in grams){
            var map_temp=HashMap<String,grammer>()
            for(j in str_temp){
                map_temp.put(j,grammer("",[]))
            }
            this.matrix.put(i.left,map_temp)
        }
    }

    func split_gram(gram:grammer):Int{
        var n=0
        for(j in 0..gram.rights.size){
            if(!gram.rights[j].startsWith(gram.left)){
                n=j
                break 
            }
            n=j+1
        }
        return n
    }

    func direct_left_recursion(n:Int,gram:grammer):(grammer,grammer,Int){
        var gram_old:grammer
        var gram_new:grammer
        var rights_old=ArrayList<String>()
        var t=0
        for(i in 0..this.grams.size where this.grams[i].left==gram.left){
            t=i
            break
        }
        var j=0
        while(j<this.grams.size){
            if(this.grams[j].left==this.grams[t].left+"\'"){
                t=j
                j=0
            }
            j++
        }
        let left_temp=this.grams[t].left
        for(j in n..gram.rights.size){
            rights_old.append(gram.rights[j]+left_temp+"\'")
        }
        var rights_new=ArrayList<String>()
        for(j in 0..n){
            rights_new.append(gram.rights[j].removePrefix(gram.left)+left_temp+"\'")
        }
        rights_new.append("ε")
        
        gram_old=gram_sort(grammer(gram.left,rights_old.toArray()))
        gram_new=gram_sort(grammer(left_temp+"\'",rights_new.toArray()))
        return (gram_old,gram_new,t+1)
    }
    

    func simplify(){
        var flag=Array<Bool>(this.grams.size,{i=>if(this.grams[i].left==start){true}else{false}})
        var queue=Queue<String>()
        queue.push(start)
        while(!queue.isEmpty()&&flag.contains(false)){
            let s=queue.pop()
            for(i in this.grams where i.left==s){
                for(j in i.rights){
                    for(k in 0..this.grams.size where j.contains(this.grams[k].left)){
                        if(flag[k]){
                            continue
                        }
                        flag[k]=true
                        queue.push(this.grams[k].left)
                    }
                }
                break
            }
        }
        var grams_new=ArrayList<grammer>()
        for(i in 0..this.grams.size where flag[i]){
            grams_new.append(this.grams[i])
        }
        this.grams=grams_new
    }

    func left_recursion_elimination(){
        this.pre_grams()
        var i=0
        while(i<this.grams.size){
            var gram_temp=this.grams[i]
            for(j in 0..i){
                var rights_new=ArrayList<String>()
                for(k in gram_temp.rights){
                    if(k.startsWith(this.grams[j].left)){
                        for(l in this.grams[j].rights){
                            let right_new:String
                            if(l!="ε"){
                                right_new=l+k.removePrefix(this.grams[j].left)
                            }
                            else{
                                right_new=k.removePrefix(this.grams[j].left)
                            }
                            if(!rights_new.contains(right_new)){
                                rights_new.append(l+k.removePrefix(this.grams[j].left))
                            }
                        }
                        continue
                    }
                    if(!rights_new.contains(k)){
                        rights_new.append(k)
                    }
                }
                gram_temp=gram_sort(grammer(gram_temp.left,rights_new.toArray()))
            }
            let n=this.split_gram(gram_temp)
            if(n==0){
                i++
                continue
            }
            let gram_old:grammer
            let gram_new:grammer
            let pos:Int
            (gram_old,gram_new,pos)=this.direct_left_recursion(n,gram_temp)
            this.grams.insert(pos,gram_new)
            this.grams[i]=gram_old
            i++
        }
        this.simplify()
    }

    func create_trie(gram:grammer):Trie_node{
        var root=Trie_node(gram.left)
        for(j in gram.rights){
            var root_temp=root
            var temp=j.clone()
            temp+="#"
            while(temp.size>0){
                var node=Trie_node()
                var flag=false
                for(k in this.grams where temp.startsWith(k.left)){
                    node.symbol=k.left
                    temp=temp.removePrefix(k.left)
                    flag=true
                    break
                }
                if(!flag){
                    node.symbol=temp.toRuneArray()[0].toString()
                    temp=temp.removePrefix(temp.toRuneArray()[0].toString())
                }
                flag=false
                for(k in root_temp.children where k.symbol==node.symbol){
                    node=k
                    flag=true
                    break   
                }
                if(!flag){
                    root_temp.children.append(node)
                }
                root_temp=node
            }
        }
        return root
    }

    func extract(){
        this.pre_grams()
        var i=0
        while(i<this.grams.size){
            var root=create_trie(this.grams[i])
            var common_max=ArrayList<String>(this.grams[i].left)
            func dfs(node:Trie_node,common:ArrayList<String>):Unit{
                var common_temp=common.clone()
                common_temp.append(node.symbol)
                if(node.children.isEmpty()){
                    return
                }
                if(node.children.size==1){
                    dfs(node.children[0],common_temp)
                    return
                }
                for(i in node.children){
                    if(common_temp.size>common_max.size){
                        common_max=common_temp.clone()
                    }
                    dfs(i,common_temp)
                }
            }
            dfs(root,ArrayList<String>())
            if(common_max.size==1){
                i++
                continue
            }
            var rights_old=ArrayList<String>()
            var common_max_str=""
            for(j in 1..common_max.size){
                common_max_str+=common_max[j]
            }
            var j=0
            var t=i
            while(j<this.grams.size){
                if(this.grams[j].left==this.grams[t].left+"\'"){
                    t=j
                    j=0
                }
                j++
            }
            rights_old.append(common_max_str+this.grams[t].left+"\'")
            var rights_new=ArrayList<String>()
            for(j in this.grams[i].rights){
                if(j.startsWith(common_max_str)){
                    if(j.size==common_max_str.size){
                        rights_new.append("ε")
                        continue
                    }
                    rights_new.append(j.removePrefix(common_max_str))
                    continue
                }
                rights_old.append(j)
            }
            this.grams[i]=gram_sort(grammer(this.grams[i].left,rights_old.toArray()))
            this.grams.insert(t+1,gram_sort(grammer(this.grams[t].left+"\'",rights_new.toArray())))
        }
    }

    func First(string:String,start!:String=string,f!:Bool=true):HashSet<String>{
        var pos=-1
        for(i in 0..this.grams.size where string.startsWith(this.grams[i].left)){
            pos=i
        }
        if(pos==-1||!this.first.contains(string)){
            return HashSet<String>(string.toRuneArray()[0].toString())
        }
        var first=HashSet<String>()
        for(i in this.grams[pos].rights){
            var flag=false
            var t=this.grams.size
            while(t>0){
                let j=this.grams[t-1]
                if(!i.startsWith(j.left)){
                    t--
                    continue
                }
                flag=true
                let first_temp:HashSet<String>
                if(!f&&j.left==start){
                    continue
                }
                if(this.first[j.left].isEmpty()){
                    first_temp=this.First(j.left,start:start,f:false)
                }
                else{
                    first_temp=this.first[j.left]
                }
                first.putAll(first_temp)
                if(first_temp.contains("ε")){
                    first.putAll(this.First(i.removePrefix(j.left)))
                }
                break
            }
            if(!flag){
                first.put(i.toRuneArray()[0].toString())
            }
        }
        return first
    }

    func First(){
        for(i in this.grams){
            this.first[i.left]=this.First(i.left)
            for(j in i.rights){
                this.first[j]=this.First(j)
            }
           
        }
    }

    func Follow(){
        this.follow[start].put("$")
        while(true){
            var follow_temp=HashMap<String,HashSet<String>>()
            for(i in this.follow){
                follow_temp.put(i[0],i[1].clone())
            }
            for(i in this.grams){
                for(j in i.rights){
                    var right_temp=j.clone()
                    var string_last=""
                    while(!right_temp.isEmpty()){
                        var string_temp=""
                        for(k in this.grams where right_temp.endsWith(k.left)){
                            string_temp=k.left
                            break
                        }
                        if(!string_temp.isEmpty()){
                            if(!string_last.isEmpty()){
                                this.follow[string_temp].putAll(this.First(string_last))
                                if(this.First(string_last).contains("ε")){
                                    this.follow[string_temp].putAll(this.follow[i.left])
                                }
                            }
                            else{
                                this.follow[string_temp].putAll(this.follow[i.left])
                            }
                            string_last=string_temp.clone()
                            right_temp=right_temp.removeSuffix(string_last)
                            continue
                        }
                        string_last=right_temp.toRuneArray()[right_temp.toRuneArray().size-1].toString()
                        right_temp=right_temp[0..right_temp.toRuneArray().size-1]
                    }
                }    
            }
            if(follow_temp==this.follow){
                break
            }
        }
        for(i in this.grams){
            follow[i.left].remove("ε")
        }
    }

    func Select(){
        for(i in this.grams){
            for(j in i.rights){
                if(first[j].contains("ε")){
                    let temp=this.first[j].clone()
                    temp.remove("ε")
                    temp.putAll(this.follow[i.left])
                    this.select[i.left+"->"+j].putAll(temp)
                    continue
                }
                let temp=this.first[j].clone()
                temp.remove("ε")
                this.select[i.left+"->"+j].putAll(temp)
            }
        }
    }

    func First_Follow_Select(){
        this.pre_grams()
        this.pre_first_follow_select_matrix()
        this.First()
        this.Follow()
        this.Select()
    }

    func judgeLL1():Bool{
        for(i in this.grams){
            for(j in 0..i.rights.size-1){
                for(k in j+1..i.rights.size){
                    for(l in this.select[i.left+"->"+i.rights[j]] where this.select[i.left+"->"+i.rights[k]].contains(l)){
                        println("not LL1")
                        return false
                    }
                }
                
            }
        }
        println("is LL1")
        return true
    }

    func create_matrix(){
        if(this.select.isEmpty()){
            this.First_Follow_Select()
        }
        if(!this.judgeLL1()){
            return
        }
        for(i in this.select){
            var gram_temp=pre_grammer(i[0])
            for(j in i[1]){
                this.matrix[gram_temp.left][j]=gram_temp
            }
        }
    }

    func parser(string:String){
        this.First_Follow_Select()
        this.create_matrix()
        var stack=Stack<String>()
        var input_buffer=string+"$"
        stack.push("$")
        stack.push(start)
        while(!stack.isEmpty()){
            var top=stack.pop()
            var current_symbol = input_buffer.toRuneArray()[0].toString()
            var t=-1
            for(i in 0..this.grams.size where top==this.grams[i].left){
                t=i
            }
            if(t==-1){
                if(top!=current_symbol){
                    println("error")
                    return
                }
                if(top=="$"){
                    println("结束")
                    return
                }
                input_buffer=input_buffer.removePrefix(current_symbol)
                println("匹配${top}")
            }
            else{
                var production=this.matrix[top][current_symbol]
                if(production.left.isEmpty()){
                    println("error")
                    return
                }
                println("输出${production.left}->${production.rights}")
                for(i in production.rights){
                    var string_temp=i.clone()
                    while(!string_temp.isEmpty()){
                        var flag=false
                        for(j in this.grams where string_temp.endsWith(j.left)){
                            stack.push(j.left)
                            string_temp=string_temp.removeSuffix(j.left)
                            flag=true
                        }
                        if(!flag){
                            let s_arr=string_temp.toRuneArray()
                            let s_temp=s_arr[s_arr.size-1].toString()
                            if(s_temp!="ε"){
                                stack.push(s_temp)
                            }
                            string_temp=string_temp.removePrefix(s_temp)
                        }
                    }
                }
            }
        }
    }

}


main() {

    //Cangjie无法输入"ε"
    let t=Console.stdIn.readln().getOrThrow()
    var n=Int.parse(t)
    let grams=ArrayList<grammer>()
    while(n>0){
        let input=Console.stdIn.readln().getOrThrow()
        grams.append(pre_grammer(input))
        n--
    } 
    //Test
    // let grams=ArrayList<grammer>()
    // grams.append(pre_grammer("E->E+T"))
    // grams.append(pre_grammer("E->T"))
    // grams.append(pre_grammer("T->T*F"))
    // grams.append(pre_grammer("T->F"))
    // grams.append(pre_grammer("F->(E)"))
    // grams.append(pre_grammer("F->i"))

    let parse=Parsing(grams)
    //左递归消除
    println("左递归消除")
    parse.left_recursion_elimination()
    for(i in parse.grams){
        println("${i.left}->${i.rights}")
    }

    //提取公共左因子
    println("提取公共左因子")
    parse.extract()
    for(i in parse.grams){
        println("${i.left}->${i.rights}")
    }

    //First Follow 集
    println("First集:")
    parse.First_Follow_Select()
    for(i in parse.first){
        println("${i[0]}: ${i[1]}")
    }
    println("Follow集:")
    for(i in parse.follow){
        println("${i[0]}: ${i[1]}")
    }

    //parser
    println("开始解析")
    parse.parser("a")
    println("预测分析表如下:")
    for(i in parse.matrix){
        for(j in i[1]){
            println("${i[0]},${j[0]}: ${j[1].left}->${j[1].rights}")
        }
    }


    return 0
}
